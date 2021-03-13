{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.bookwyrm.url = "github:mmai/bookwyrm-flake";
  # inputs.bookwyrm.url = "/home/henri/travaux/nix-flakes/bookwyrm-flake/";

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

            # Network configuration.
            networking.useDHCP = false;
            networking.firewall.allowedTCPPorts = [ 80 ];
            networking.hostName = hostname;

            nixpkgs.overlays = [ bookwyrm.overlay ];

            services.bookwyrm = {
              enable = true;
              hostname = hostname;
              defaultFromEmail = "noreply@funkwhale.rhumbs.fr";
              protocol = "http"; # no ssl for virtualbox
              forceSSL = false; # uncomment when LetsEncrypt needs to access "http:" in order to check domain
              api = {
                  # Generate one using `openssl rand -base64 45`, for example
                  djangoSecretKey = "yoursecretkey";
                };
              };

              # Overrides default 30M
              services.nginx.clientMaxBodySize = "100m";

            })
        ];
      };

    };
  };
}
