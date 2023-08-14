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
        version = "v0.6.3";
        src = fetchFromGitHub {
          owner = "mouse-reeve";
          repo = "bookwyrm";
          rev = "6400a8e23408158fe3d253b8ce9578d04968048a";
          sha256 = "bCn6YM9WcOTm0y0pTjmNUsohQ8PM7tpgtNmPrAN4d5k=";
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

    django-imagekit = with final; with pkgs.python3.pkgs; ( buildPythonPackage rec {
      pname = "django-imagekit";
      version = "4.1.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "e559aeaae43a33b34f87631a9fa5696455e4451ffa738a42635fde442fedac5c"; #tar.gz
      };
      propagatedBuildInputs = [ django ];
      # doCheck = false;

      meta = with lib; {
        description = "Automated image processing for Django models";
        homepage = "http://github.com/matthewwithanm/django-imagekit/";
        license = licenses.bsd;
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
      # doCheck = false;

      meta = with lib; {
        description = "SASS processor to compile SCSS files into *.css, while rendering, or offline";
        homepage = "https://github.com/jrief/django-sass-processor";
        license = licenses.mit;
        maintainers = with maintainers; [ mmai ];
      };
    });

  };

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
