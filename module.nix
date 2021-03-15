{config, lib, pkgs, ...}:

with lib;

let
  pythonEnv = (pkgs.python3.override {
    packageOverrides = self: super: rec {
      django = self.django_3;
    };
  }).withPackages (ps: [
    ps.celery
    # ps.flower
    ps.django
    ps.markdown
    ps.pillow
    ps.psycopg2
    ps.redis
    ps.requests
    ps.gunicorn
    ps.pycryptodome
    ps.dateutil
    ps.responses

    pkgs.environs
    pkgs.django-rename-app
    pkgs.django-model-utils
  ]);

  cfg = config.services.bookwyrm;

  databasePassword = if (cfg.database.passwordFile != null) 
    then builtins.readFile cfg.database.passwordFile
    else cfg.database.password;
  # redisPassword = if (cfg.redis.passwordFile != null) 
  #   then builtins.readFile cfg.redis.passwordFile
  #   else cfg.redis.password;
  # flowerPassword = if (cfg.flower.passwordFile != null) 
  #   then builtins.readFile cfg.flower.passwordFile
  #   else cfg.flower.password;
  emailPassword = if (cfg.email.passwordFile != null) 
    then builtins.readFile cfg.email.passwordFile
    else cfg.email.password;

  bookwyrmEnvironment = {
    SECRET_KEY="${cfg.api.djangoSecretKey}";
    DEBUG="false";
    DOMAIN="${cfg.hostname}";
    EMAIL="${cfg.defaultFromEmail}";
    OL_URL="https://openlibrary.org";
    BOOKWYRM_DATABASE_BACKEND="postgres";
    MEDIA_ROOT="${cfg.api.mediaRoot}";
    STATIC_ROOT="${cfg.api.staticRoot}";

    POSTGRES_PASSWORD="${databasePassword}";
    POSTGRES_USER="${cfg.database.user}";
    POSTGRES_DB="${cfg.database.name}";
    POSTGRES_HOST="${cfg.database.host}";

    # REDIS_PASSWORD="${redisPassword}"; # no nixos password settings ?
    REDIS_PASSWORD="-";
    CELERY_BROKER="redis://localhost:${toString config.services.redis.port}/0";
    CELERY_RESULT_BACKEND="redis://localhost:${toString config.services.redis.port}/0";

    # FLOWER_PORT="${flower.port}";
    # FLOWER_USER="${flower.user}";
    # FLOWER_PASSWORD="${flowerPassword}";

    EMAIL_HOST="${cfg.email.host}";
    EMAIL_PORT="${toString cfg.email.port}";
    EMAIL_HOST_USER="${cfg.email.user}";
    EMAIL_HOST_PASSWORD="${emailPassword}";
    EMAIL_USE_TLS="true";
  };

  bookwyrmEnvList = (map (key: key + "=" + (getAttr key bookwyrmEnvironment)) (attrNames bookwyrmEnvironment));

  bookwyrmEnvFileData = builtins.concatStringsSep "\n" bookwyrmEnvList;
  bookwyrmEnvScriptData = builtins.concatStringsSep " " bookwyrmEnvList;

  bookwyrmEnvFile = pkgs.writeText "bookwyrm.env" bookwyrmEnvFileData;
  bookwyrmEnv = {
    ENV_FILE = "${bookwyrmEnvFile}";
  };
in 
  {

    options = {
      services.bookwyrm = {
        enable = mkEnableOption "bookwyrm";

        user = mkOption {
          type = types.str;
          default = "bookwyrm";
          description = "User under which bookwyrm is ran.";
        };

        group = mkOption {
          type = types.str;
          default = "bookwyrm";
          description = "Group under which bookwyrm is ran.";
        };

        # redis = {
        #   password = mkOption {
        #     type = types.str;
        #     default = "";
        #     description = ''
        #       The Redis password.
        #       Warning: this is stored in cleartext in the Nix store!
        #       Use <option>redis.passwordFile</option> instead.
        #     '';
        #   };
        #
        #   passwordFile = mkOption {
        #     type = types.nullOr types.path;
        #     default = null;
        #     example = "/run/keys/bookwyrm-redispassword";
        #     description = ''
        #       A file containing the redis password
        #     '';
        #   };
        # };

        # flower = {
        #   port = mkOption {
        #     type = types.int;
        #     default = 8888;
        #     description = "Flower port.";
        #   };
        #
        #   user = mkOption {
        #     type = types.str;
        #     default = "bookwyrm";
        #     description = "Flower user.";
        #   };
        #
        #   password = mkOption {
        #     type = types.str;
        #     default = "";
        #     description = ''
        #       The Flower password.
        #       Warning: this is stored in cleartext in the Nix store!
        #       Use <option>flower.passwordFile</option> instead.
        #     '';
        #   };
        #
        #   passwordFile = mkOption {
        #     type = types.nullOr types.path;
        #     default = null;
        #     example = "/run/keys/bookwyrm-flowerpassword";
        #     description = ''
        #       A file containing the flower password corresponding to
        #       <option>flower.user</option>.
        #     '';
        #   };
        # };

        database = {
          host = mkOption {
            type = types.str;
            default = "localhost";
            description = "Database host address.";
          };

          port = mkOption {
            type = types.int;
            default = 5432;
            description = "Database host port.";
          };

          name = mkOption {
            type = types.str;
            default = "bookwyrm";
            description = "Database name.";
          };

          user = mkOption {
            type = types.str;
            default = "bookwyrm";
            description = "Database user.";
          };

          password = mkOption {
            type = types.str;
            default = "dbpass";
            description = ''
              The password corresponding to <option>database.user</option>.
              Warning: this is stored in cleartext in the Nix store!
              Use <option>database.passwordFile</option> instead.
            '';
          };

          passwordFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            example = "/run/keys/bookwyrm-dbpassword";
            description = ''
              A file containing the password corresponding to
              <option>database.user</option>.
            '';
          };

          socket = mkOption {
            type = types.nullOr types.path;
            default = "/run/postgresql";
            description = "Path to the unix socket file to use for authentication for local connections.";
          };

          createLocally = mkOption {
            type = types.bool;
            default = true;
            description = "Create the database and database user locally.";
          };
        };

        dataDir = mkOption {
          type = types.str;
          default = "/srv/bookwyrm";
          description = ''
            Where to keep the bookwyrm data.
          '';
        };

        apiIp = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = ''
            bookwyrm API IP.
          '';
        };

        webWorkers = mkOption {
          type = types.int;
          default = 1;
          description = ''
            bookwyrm number of web workers.
          '';
        };

        apiPort = mkOption {
          type = types.port;
          default = 8000;
          description = ''
            bookwyrm API Port.
          '';
        };

        hostname = mkOption {
          type = types.str;
          description = ''
            The definitive, public domain you will use for your instance.
          '';
          example = "bookwyrm.yourdomain.net";
        };

        protocol = mkOption {
          type = types.enum [ "http" "https" ];
          default = "https";
          description = ''
            Web server protocol.
          '';
        };

        forceSSL = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Force SSL : put this to 'false' when Let's Encrypt has problems calling 'http:' to check the domain
          '';
        };

        email = {
          host = mkOption {
            type = types.str;
            description = ''
              Email server host
            '';
            example = "smtp.mailgun.org";
          };

          port = mkOption {
            type = types.port;
            default = 587;
            description = ''
              Email serveur port.
            '';
          };

          user = mkOption {
            type = types.str;
            description = ''
              Email server user
            '';
            example = "mail@your.domain.here";
          };

          password = mkOption {
            type = types.str;
            default = "";
            description = ''
              The Email server password.
              Warning: this is stored in cleartext in the Nix store!
              Use <option>email.passwordFile</option> instead.
            '';
          };

          passwordFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            example = "/run/keys/bookwyrm-emailpassword";
            description = ''
              A file containing the email server password
            '';
          };
        };

        defaultFromEmail = mkOption {
          type = types.str;
          description = ''
            The email address to use to send system emails.
          '';
          example = "bookwyrm@yourdomain.net";
        };

        api = {
          mediaRoot = mkOption {
            type = types.str;
            default = "/srv/bookwyrm/images";
            description = ''
              Where media files (such as book covers) should be stored on your system.
            '';
          };

          staticRoot = mkOption {
            type = types.str;
            default = "/srv/bookwyrm/static";
            description = ''
              Where static files (such as API css or icons) should be compiled on your system.
            '';
          };

          djangoSecretKey = mkOption {
            type = types.str;
            description = ''
              Django secret key. Generate one using <command>openssl rand -base64 45</command> for example.
            '';
            example = "6VhAWVKlqu/dJSdz6TVgEJn/cbbAidwsFvg9ddOwuPRssEs0OtzAhJxLcLVC";
          };
        };
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        { assertion = cfg.database.passwordFile != null || cfg.database.password != "" || cfg.database.socket != null;
          message = "one of services.bookwyrm.database.socket, services.bookwyrm.database.passwordFile, or services.bookwyrm.database.password must be set";
        }
        { assertion = cfg.database.createLocally -> cfg.database.user == cfg.user;
          message = "services.bookwyrm.database.user must be set to ${cfg.user} if services.bookwyrm.database.createLocally is set true";
        }
        { assertion = cfg.database.createLocally -> cfg.database.socket != null;
          message = "services.bookwyrm.database.socket must be set if services.bookwyrm.database.createLocally is set to true";
        }
        { assertion = cfg.database.createLocally -> cfg.database.host == "localhost";
          message = "services.bookwyrm.database.host must be set to localhost if services.bookwyrm.database.createLocally is set to true";
        }
      ];

      users.users.bookwyrm = mkIf (cfg.user == "bookwyrm") { group = cfg.group; };
      users.groups.bookwyrm = mkIf (cfg.group == "bookwyrm") {};

      services.postgresql = mkIf cfg.database.createLocally {
        enable = true;
        ensureDatabases = [ cfg.database.name ];
        ensureUsers = [
          { name = cfg.database.user;
            ensurePermissions = { "DATABASE ${cfg.database.name}" = "ALL PRIVILEGES"; };
          }
        ];

        authentication = lib.mkForce ''
          local all postgres               trust
          local ${cfg.database.name} ${cfg.database.user}               trust
          host  ${cfg.database.name} ${cfg.database.user} 127.0.0.1/32 trust
          host  ${cfg.database.name} ${cfg.database.user} ::1/128      trust
        '';
      };

      services.redis.enable =  true;

      services.nginx = {
        enable = true;
        appendHttpConfig = ''
          upstream bookwyrm-api {
          server ${cfg.apiIp}:${toString cfg.apiPort};
          }
        '';
        virtualHosts = 
        let proxyConfig = ''
          # global proxy conf
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $host:$server_port;
          proxy_set_header X-Forwarded-Port $server_port;
          proxy_redirect off;

          # websocket support
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;
        '';
        withSSL = cfg.protocol == "https";
        in {
          "${cfg.hostname}" = {
            enableACME = withSSL;
            forceSSL = cfg.forceSSL;
            root = "${cfg.dataDir}/front";
          # gzip config is nixos nginx recommendedGzipSettings with gzip_types 
          # from funkwhale doc (https://docs.funkwhale.audio/changelog.html#id5)
            extraConfig = ''
              add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
              add_header Referrer-Policy "strict-origin-when-cross-origin";

              gzip on;
              gzip_disable "msie6";
              gzip_proxied any;
              gzip_comp_level 5;
              gzip_types
              application/javascript
              application/vnd.geo+json
              application/vnd.ms-fontobject
              application/x-font-ttf
              application/x-web-app-manifest+json
              font/opentype
              image/bmp
              image/svg+xml
              image/x-icon
              text/cache-manifest
              text/css
              text/plain
              text/vcard
              text/vnd.rim.location.xloc
              text/vtt
              text/x-component
              text/x-cross-domain-policy;
              gzip_vary on;
            '';
            locations = {
              "/" = { 
                extraConfig = proxyConfig;
                proxyPass = "http://bookwyrm-api/";
              };
              "/images/".alias = "${cfg.api.mediaRoot}/";
              "/static/".alias = "${cfg.api.staticRoot}/";
            };
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.api.mediaRoot} 0755 ${cfg.user} ${cfg.group} - -"
        "d ${cfg.api.staticRoot} 0755 ${cfg.user} ${cfg.group} - -"
      ];

      systemd.targets.bookwyrm = {
        description = "bookwyrm";
        wants = ["bookwyrm-server.service" "bookwyrm-worker.service"];
      }; 
      systemd.services = 
      let serviceConfig = {
        User = "${cfg.user}";
        WorkingDirectory = "${pkgs.bookwyrm}";
      };
      in {
        bookwyrm-psql-init = mkIf cfg.database.createLocally {
          description = "bookwyrm database preparation";
          after = [ "redis.service" "postgresql.service" ];
          wantedBy = [ "bookwyrm-init.service" ];
          before   = [ "bookwyrm-init.service" ];
          serviceConfig = {
            User = "postgres";
            ExecStart = '' ${config.services.postgresql.package}/bin/psql \
              -d ${cfg.database.name}  -c 'CREATE EXTENSION IF NOT EXISTS \
              "unaccent";CREATE EXTENSION IF NOT EXISTS "pg_trgm";' '';
          };
        };
        bookwyrm-init = {
          description = "bookwyrm initialization";
          wantedBy = [ "bookwyrm-server.service" "bookwyrm-worker.service" ];
          before   = [ "bookwyrm-server.service" "bookwyrm-worker.service" ];
          environment = bookwyrmEnvironment;
          serviceConfig = serviceConfig // {
            Group = "${cfg.group}";
          };
          script = ''
            ${bookwyrmEnvScriptData} ${pythonEnv.interpreter} ${pkgs.bookwyrm}/manage.py migrate
            ${bookwyrmEnvScriptData} ${pythonEnv.interpreter} ${pkgs.bookwyrm}/manage.py collectstatic --no-input
            if ! test -e ${cfg.dataDir}/config; then
              ${bookwyrmEnvScriptData} ${pythonEnv.interpreter} ${pkgs.bookwyrm}/manage.py initdb
              mkdir -p ${cfg.dataDir}/config
              ln -s ${bookwyrmEnvFile} ${cfg.dataDir}/config/.env
              ln -s ${bookwyrmEnvFile} ${cfg.dataDir}/.env
            fi
          '';
        };

        bookwyrm-server = {
          description = "bookwyrm application server";
          partOf = [ "bookwyrm.target" ];

          serviceConfig = serviceConfig // { 
            ExecStart = ''${pythonEnv}/bin/gunicorn bookwyrm.wsgi:application \
              -w ${toString cfg.webWorkers} \
              -b ${cfg.apiIp}:${toString cfg.apiPort}'';
          };
          environment = bookwyrmEnvironment;

          wantedBy = [ "multi-user.target" ];
        };

        bookwyrm-worker = {
          description = "bookwyrm celery worker";
          partOf = [ "bookwyrm.target" ];

          serviceConfig = serviceConfig // { 
            RuntimeDirectory = "bookwyrmworker"; 
            ExecStart = "${pythonEnv}/bin/celery -A celerywyrm worker -l info";
          };
          environment = bookwyrmEnvironment;

          wantedBy = [ "multi-user.target" ];
        };

      };

    };

    meta = {
      maintainers = with lib.maintainers; [ mmai ];
    };
  }
