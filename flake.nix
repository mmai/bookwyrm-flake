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
          version = "0.0.1";
          src = fetchFromGithub {
            owner = "mouse-reeve";
            repo = "bookwyrm";
            rev = "a63471c56f6d8b88001b77990fdbae2964a3118b";
            sha256 = "1rs9bxxrw4wscf4a8yl776a8g880m5gcm75q06yx2cn3lw2b7v22";
          };

          installPhase = ''
            mkdir $out
            cp -R ./* $out
          '';

          meta = with stdenv.lib; {
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
    };

    # ------- Python dependencies missing from nixos -----------

    django-model-utils = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "django-model-utils";
      version = "4.1.1";

      src = fetchPypi {
        inherit pname version;
        sha256 = "sha256-ef7c440024e797796a3811432abdd2be8b5225ae64ef346f8bfc6de7d8e5d73c"; # wheel
        # sha256 = "sha256-eb5dd05ef7d7ce6bc79cae54ea7c4a221f6f81e2aad7722933aee66489e7264b"; #tar.gz
      };
      # propagatedBuildInputs = [ tox sphinx twine freezegun ];
      # doCheck = false;

      meta = with stdenv.lib; {
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
        sha256 = "sha256-2da44b7c30114415aa858577fa6396ee326fc76a0a60f0f15e8260ba554f19dc"; # wheel
        # sha256 = "sha256-3f6def554abb5455141b540e6e0b72fda3853404f2b0d31658aab1bf95410db3"; #tar.gz
      };
      propagatedBuildInputs = [ marshmallow python-dotenv dj-database-url dj-email-url django-cache-url ]
      # doCheck = false;

      meta = with stdenv.lib; {
        description = "Simplified environment variable parsing";
        homepage = "https://github.com/sloria/environs";
        license = licenses.mit;
        maintainers = with maintainers; [ mmai ];
      };
    });

    django-rename-app = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "django-rename-app";
      version = "0.1.2";

      src = fetchPypi {
        inherit pname version;
        sha256 = "sha256-47e9954cdb26ac1b2b0c951e9d630cd8d79b733bb7713e0d137a8a969af31e5a"; # wheel
        # sha256 = "sha256-d59990f11e0e5c73fff62122daf4dbd52185dc1e050e3b41fd7954f579fca056"; #tar.gz
      };
      propagatedBuildInputs = [ django ]
      # doCheck = false;

      meta = with stdenv.lib; {
        description = "A Django Management Command to rename existing Django Applications";
        homepage = "https://github.com/odwyersoftware/django-rename-app";
        license = licenses.mit;
        maintainers = with maintainers; [ mmai ];
      };
    });

    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) bookwyrm;

      inherit (nixpkgsFor.${system}) environs;
      inherit (nixpkgsFor.${system}) django-rename-app;
      inherit (nixpkgsFor.${system}) django-model-utils;
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.bookwyrm);


    # bookwyrm service module
    nixosModule = (import ./module.nix);

  };
}
