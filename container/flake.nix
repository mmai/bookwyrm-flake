{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  # inputs.bookwyrm.url = "github:mmai/bookwyrm-flake";
  inputs.bookwyrm.url = "/home/henri/travaux/nix_flakes/bookwyrm-flake/";

  outputs = { self, nixpkgs, bookwyrm }: 
   {
    nixosConfigurations = {

      container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          bookwyrm.nixosModule
          ( { pkgs, ... }: 
          let hostname = "bookwyrm";
          in {
            boot.isContainer = true;

            # Let 'nixos-version --json' know about the Git revision
            # of this flake.
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            system.stateVersion = "23.05";

            # Network configuration.
            networking.useDHCP = false;
            networking.firewall.allowedTCPPorts = [ 80 443 8888 ]; # 8888 : flower
            networking.hostName = hostname;

            # We use a self-signed SSL certificate for the container version
            security.acme = {
              acceptTerms = true;
              defaults = {
                server = "https://127.0.0.1";
                email = "email@email.fr";
              };
              preliminarySelfsigned = true;
            };

            nixpkgs.overlays = [ bookwyrm.overlay ];

            services.bookwyrm = {
              enable = true;
              hostname = hostname;
              defaultFromEmail = "noreply@funkwhale.rhumbs.fr";
              api = {
                  # Generate one using `openssl rand -base64 45`, for example
                  djangoSecretKey = "yoursecretkey";
              };

              email = {
                host = "smtp.gmail.com";
                user = "-";
                password = "-";
              };

              flowerArgs = [ "--port=8888" ];

              celeryRedis.createLocally = true;
              activityRedis.createLocally = true;
            };

            # Overrides default 30M
            services.nginx.clientMaxBodySize = "100m";

          })
        ];
      };

    };
  };
}
