{
  description = "Bookwyrm";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.09;

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
        version = "0.0.20210315";
        src = fetchFromGitHub {
          owner = "mouse-reeve";
          repo = "bookwyrm";
          rev = "e8b89eee73e6b27c50ab562bfc6b9a78007020ae";
          sha256 = "bCn7YM9WcOTm0y0pTjmNUsohQ8PM7tpgtNmPrAN4d5k=";
        };

        installPhase = ''
            mkdir $out
            cp -R ./* $out
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

    django-model-utils = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "django-model-utils";
      version = "4.1.1";

      src = fetchPypi {
        inherit pname version;
        sha256 = "eb5dd05ef7d7ce6bc79cae54ea7c4a221f6f81e2aad7722933aee66489e7264b"; #tar.gz
      };
      propagatedBuildInputs = [ django_3 ];
      buildInputs = [ tox sphinx twine freezegun ];
      doCheck = false;

      meta = with lib; {
        description = "Django model mixins and utilities";
        homepage = "https://github.com/jazzband/django-model-utils";
        license = licenses.bsd3;
        maintainers = with maintainers; [ mmai ];
      };
    });

    environs = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "environs";
      version = "9.3.1";

      src = fetchPypi {
        inherit pname version;
        sha256 = "3f6def554abb5455141b540e6e0b72fda3853404f2b0d31658aab1bf95410db3"; #tar.gz
      };
      propagatedBuildInputs = [ marshmallow python-dotenv dj-database-url dj-email-url django-cache-url ];
      # doCheck = false;

      meta = with lib; {
        description = "Simplified environment variable parsing";
        homepage = "https://github.com/sloria/environs";
        license = licenses.mit;
        maintainers = with maintainers; [ mmai ];
      };
    });

    django-rename-app = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "django_rename_app";
      version = "0.1.2";

      src = fetchPypi {
        inherit pname version;
        sha256 = "d59990f11e0e5c73fff62122daf4dbd52185dc1e050e3b41fd7954f579fca056"; #tar.gz
      };
      propagatedBuildInputs = [ django_3 ];
      # doCheck = false;

      meta = with lib; {
        description = "A Django Management Command to rename existing Django Applications";
        homepage = "https://github.com/odwyersoftware/django-rename-app";
        license = licenses.mit;
        maintainers = with maintainers; [ mmai ];
      };
    });

    # copied from unstable nixos branch
    django_3 = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "Django";
      version = "3.1.7";

      disabled = pythonOlder "3.7";

      src = fetchPypi {
        inherit pname version;
        sha256 = "32ce792ee9b6a0cbbec340123e229ac9f765dff8c2a4ae9247a14b2ba3a365a7";
      };

      propagatedBuildInputs = [
        asgiref
        pytz
        sqlparse
      ];

      # too complicated to setup
      doCheck = false;

      meta = with lib; {
        description = "A high-level Python Web framework";
        homepage = "https://www.djangoproject.com/";
        license = licenses.bsd3;
        maintainers = with maintainers; [ georgewhewell lsix ];
      };
    });

  };

    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) bookwyrm;

      inherit (nixpkgsFor.${system}) environs;
      inherit (nixpkgsFor.${system}) django-rename-app;
      inherit (nixpkgsFor.${system}) django-model-utils;
      inherit (nixpkgsFor.${system}) django_3;
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.bookwyrm);


    # bookwyrm service module
    nixosModule = (import ./module.nix);

  };
}
