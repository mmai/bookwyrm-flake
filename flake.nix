{
  description = "Bookwyrm";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-23.05;
  #inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system); 
    # Memoize nixpkgs for different platforms for efficiency.
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      }
    );
  in {
    overlay = final: prev: {
      bookwyrm = with final; (stdenv.mkDerivation {
        name = "bookwyrm";
        version = "v0.6.5";
        src = fetchFromGitHub {
          owner = "mouse-reeve";
          repo = "bookwyrm";
          rev = "f0af79840852f15bd02e19586d733c3f7d79754c";
          sha256 = "yc6hgShXH2ffcUthG9f3aHIi9zrc0dtBgGYh/veNZ6M=";
        };
        patches = [ ./testchanges.patch ];

        installPhase = ''
            mkdir $out
            cp -R ./* $out
        '';

        fixupPhase = ''
          substituteInPlace $out/bookwyrm/management/commands/compile_themes.py \
            --replace 'settings.BASE_DIR, "bookwyrm", "static"' "os.environ['STATIC_ROOT']"
        '';

        meta = with lib; {
          description = "Social reading and reviewing, decentralized with ActivityPub";
          homepage = https://bookwyrm.social/;
          license = {
            shortName = "ACSL";
            fullName = "Anti-Capitalist Software License";
            url = "https://anticapitalist.software/";
          };
          platforms = platforms.linux;
          maintainers = with maintainers; [ mmai ];
        };
      });

    # ------- Python dependencies missing from nixos -----------

    django-imagekit = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "django-imagekit";
      version = "4.1.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "e559aeaae43a33b34f87631a9fa5696455e4451ffa738a42635fde442fedac5c"; #tar.gz
      };
      propagatedBuildInputs = [ django django-appconf pilkit six ];
      doCheck = false;

      meta = with lib; {
        description = "Automated image processing for Django models";
        homepage = "http://github.com/matthewwithanm/django-imagekit/";
        license = licenses.bsd3;
        maintainers = with maintainers; [ mmai ];
      };
    });

    django-sass-processor = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "django-sass-processor";
      version = "1.2.2";

      src = fetchPypi {
        inherit pname version;
        sha256 = "f6098c181cc95a21593df6bb502791e32015615222803de216fdcc8bb42c0f77"; #tar.gz
      };
      propagatedBuildInputs = [ django ];
      doCheck = false;

      meta = with lib; {
        description = "SASS processor to compile SCSS files into *.css, while rendering, or offline";
        homepage = "https://github.com/jrief/django-sass-processor";
        license = licenses.mit;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-api = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-api";
      version = "1.19.0";
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_api";
        sha256 = "db374fb5bea00f3c7aa290f5d94cea50b659e6ea9343384c5f6c2bb5d5e8db65"; #tar.gz 1.19
      };
      format = "pyproject";
      propagatedBuildInputs = [ hatchling importlib-metadata deprecated ];
      doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Python API";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-api";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-sdk = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-sdk";
      version = "1.19.0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling opentelemetry-api typing-extensions opentelemetry-semantic-conventions ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_sdk";
        sha256 = "765928956262c7a7766eaba27127b543fb40ef710499cad075f261f52163a87f"; #tar.gz
        # sha256 = "4d3bb91e9e209dbeea773b5565d901da4f76a29bf9dbc1c9500be3cabb239a4e"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Python SDK";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-sdk";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-exporter-otlp-proto-grpc = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-exporter-otlp-proto-grpc";
      version = "1.19.0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling googleapis-common-protos opentelemetry-api grpcio opentelemetry-proto opentelemetry-sdk backoff opentelemetry-exporter-otlp-proto-common ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_exporter_otlp_proto_grpc";
        sha256 = "e69261b4da8cbaa42d9b5f1cff4fcebbf8a3c02f85d69a8aea698312084f4180"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "Jaeger Protobuf Exporter for OpenTelemetry";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/exporter/opentelemetry-exporter-jaeger-proto-grpc";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-exporter-otlp-proto-common = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-exporter-otlp-proto-common";
      version = "1.19.0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling googleapis-common-protos opentelemetry-api opentelemetry-proto ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_exporter_otlp_proto_common";
        sha256 = "c13d02a31dec161f8910d96db6b58309af17d92b827c64284bf85eec3f2d7297"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Protobuf encoding";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/exporter/opentelemetry-exporter-jaeger-proto-common";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-proto = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-proto";
      version = "1.19.0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling protobuf ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_proto";
        sha256 = "sha256-vlMgViLYXs036792Su2QfYdiCkXq5jiGDLWneL+QDAQ="; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Python Proto";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-proto";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-instrumentation-celery = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-instrumentation-celery";
      # version = "0.37b0";
      version = "0.40b0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling opentelemetry-api opentelemetry-semantic-conventions opentelemetry-instrumentation ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_instrumentation_celery";
        # sha256 = "a957e67ccea7cbb65f57f7c4d8428930c8196d20a40f0a90f3e7ae3381ee74fe"; #tar.gz
        sha256 = "273412b9994290339e9d7a6fbf6ee8a776f3a2cf4c2632277d5f83d4ddd41276"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Celery Instrumentation";
        homepage = "https://github.com/open-telemetry/opentelemetry-python-contrib/tree/main/instrumentation/opentelemetry-instrumentation-celery";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-instrumentation-django = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-instrumentation-django";
      # version = "0.37b0";
      version = "0.40b0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling opentelemetry-semantic-conventions opentelemetry-instrumentation-wsgi ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_instrumentation_django";
        sha256 = "0fa606058f8f84c69f2ab9400e081e819a28bc697d6b9f7168cd9891fa95174a"; #tar.gz
        # sha256 = "84c151661ecf74996c0d7d237e2d37db45acbc4c0b28b634e946889cf5a533f7"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Instrumentation for django";
        homepage = "https://github.com/open-telemetry/opentelemetry-python-contrib/tree/main/instrumentation/opentelemetry-instrumentation-django";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-instrumentation-psycopg2 = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-instrumentation-psycopg2";
      # version = "0.37b0";
      version = "0.40b0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling opentelemetry-semantic-conventions opentelemetry-api opentelemetry-instrumentation opentelemetry-instrumentation-dbapi ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_instrumentation_psycopg2";
        sha256 = "f767ba76df2644a3e06055d4cd7ba69225fd14e77028c3672ee151894d26f11e"; #tar.gz
        # sha256 = "d62ecfce1460cdb9b80576e169f510ea8401af63135d1f6f3127259859e556cd"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry PsycoPg Instrumentation";
        homepage = "https://github.com/open-telemetry/opentelemetry-python-contrib/tree/main/instrumentation/opentelemetry-instrumentation-psycopg2";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-semantic-conventions = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-semantic-conventions";
      # version = "0.37b0";
      version = "0.40b0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_semantic_conventions";
        sha256 = "5a7a491873b15ab7c4907bbfd8737645cc87ca55a0a326c1755d1b928d8a0fae"; #tar.gz
        # sha256 = "087ce2e248e42f3ffe4d9fa2303111de72bb93baa06a0f4655980bc1557c4228"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Semantic Conventions";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-semantic-conventions";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-instrumentation = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-instrumentation";
      version = "0.40b0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling setuptools wrapt opentelemetry-api ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_instrumentation";
        sha256 = "08bebe6a752514ed61e901e9fee5ccf06ae7533074442e707d75bb65f3e0aa17"; #tar.gz
      };
      doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Instrumentation";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-instrumentation";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-instrumentation-wsgi = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-instrumentation-wsgi";
      version = "0.40b0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling opentelemetry-api opentelemetry-semantic-conventions opentelemetry-util-http opentelemetry-instrumentation-dbapi ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_instrumentation_wsgi";
        sha256 = "36f8532b605bcd8215ee3a0ee769984c4b3875c1bb63fff03a4fa3fffea6eaf2"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Instrumentation WSGI";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-instrumentation-wsgi";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-instrumentation-dbapi = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-instrumentation-dbapi";
      version = "0.40b0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling opentelemetry-api opentelemetry-semantic-conventions opentelemetry-instrumentation ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_instrumentation_dbapi";
        sha256 = "c49816c0466d2b46897339a3045cecc83e9308b0417c279e65478ec7031146b2"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Instrumentation dbapi";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-instrumentation-dbapi";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    opentelemetry-util-http = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "opentelemetry-util-http";
      version = "0.40b0";
      format = "pyproject";
      propagatedBuildInputs = [ hatchling opentelemetry-api opentelemetry-semantic-conventions ];
      src = fetchPypi {
        inherit version;
        pname = "opentelemetry_util_http";
        sha256 = "47d93efa1bb6c71954a5c6ae29a9546efae77f6875dc6c807a76898e0d478b80"; #tar.gz
      };
      # doCheck = false;
      meta = with lib; {
        description = "OpenTelemetry Util HTTP";
        homepage = "https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-util-http";
        license = licenses.asl20;
        maintainers = with maintainers; [ mmai ];
      };
    });

    };

    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) bookwyrm;

      inherit (nixpkgsFor.${system}) django-imagekit;
      inherit (nixpkgsFor.${system}) django-sass-processor;
      inherit (nixpkgsFor.${system}) opentelemetry-api;
      inherit (nixpkgsFor.${system}) opentelemetry-sdk;
      inherit (nixpkgsFor.${system}) opentelemetry-exporter-otlp-proto-grpc;
      inherit (nixpkgsFor.${system}) opentelemetry-instrumentation-psycopg2;
      inherit (nixpkgsFor.${system}) opentelemetry-instrumentation-celery;
      inherit (nixpkgsFor.${system}) opentelemetry-instrumentation-django;
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.bookwyrm);


    # bookwyrm service module
    nixosModule = (import ./module.nix);

  };
}
