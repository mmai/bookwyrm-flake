# Bookwyrm flake

Below is an example of a nixos configuration using this flake, you can also take a look at the _container/flake.nix_ file :

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  inputs.bookwyrm.url = "github:mmai/bookwyrm-flake";

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
            networking.firewall.allowedTCPPorts = [ 80 443 ]; # add 8888 to access flower
            networking.hostName = hostname;

            nixpkgs.overlays = [ bookwyrm.overlay ];

            services.bookwyrm = {
              enable = true;
              hostname = hostname;
              defaultFromEmail = "noreply@funkwhale.rhumbs.fr";
              protocol = "http"; # no ssl for container
              forceSSL = false; # uncomment when LetsEncrypt needs to access "http:" in order to check domain
              api = {
                  # Generate one using `openssl rand -base64 45`, for example
                  djangoSecretKey = "yoursecretkey";
              };

              email = {
                host = "smtp.xxxx.com";
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
```

## Test on a local container

- start the bookwyrm services in a container on the local machine : `make local`
- wait 30s for the bootstraping of bookwyrm services
- get the admin code with `sudo nixos-container run bookwyrm -- bookwyrm-manage admin_code`
- connect to the local service: browse to `firefox https://bookwyrm` and accept the auto-signed ssl certificate.

## Alternatives

For an other Bookwyrm flake, see https://git.underscore.world/d/bookwyrm.

