# Bookwyrm flake

Below is an example of a nixos configuration using this flake :

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.funkwhale.url = "github:mmai/bookwyrm-nixos";

  outputs = { self, nixpkgs, funkwhale }: 
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations = {

      server-hostname = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [ 
          nixpkgs.nixosModules.notDetected
	        funkwhale.nixosModule
          ( { config, pkgs, ... }:
            { imports = [ ./hardware-configuration.nix ];

              nix = {
                package = pkgs.nixUnstable;
                extraOptions = ''
                  experimental-features = nix-command flakes
                '';
              };

              nixpkgs.overlays = [ funkwhale.overlay ];

              services.funkwhale = {
                enable = true;
                hostname = "bookwyrm.rhumbs.fr";
                defaultFromEmail = "noreply@bookwyrm.rhumbs.fr";
                protocol = "https";
                # forceSSL = false; # uncomment when LetsEncrypt needs to access "http:" in order to check domain
                api = {
                  # Generate one using `openssl rand -base64 45`, for example
                  djangoSecretKey = "yoursecretkey";
                };
              };

              security.acme = {
                email = "your@email.com";
                acceptTerms = true;
              };

              # Overrides default 30M
              services.nginx.clientMaxBodySize = "100m";

              services.fail2ban.enable = true;
              networking.firewall.allowedTCPPorts = [ 80 443 ];
            })
        ];
      };

    };
  };
}
```
