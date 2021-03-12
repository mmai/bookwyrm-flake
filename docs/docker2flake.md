# Docker to flake

Look at docker-compose.yml and list services to implement, ordering them by dependencies.

* [x] db
* [x] redis
* [x] celery-worker (depends on db & redis)
* [x] web (depends on celery-worker)
* [] nginx (depends on web)
* certbot : bot letsencrypt -> déjà géré par nixos
* flower (depends on db & redis) : celery monitoring -> on déporte en dehors du flake bookwyrm

## General module.nix conf

* replicate .env.example in bookwyrmEnvironment with corresponding options

## DB



## Web : Django

look at requirements.txt and add python packages (except dev dependencies) in the pythonEnv of modules.nix. If some are missing from nixos packages, create their derivation definition in flake.nix

Already in nixos: 
- celery==4.4.2
- Django==3.0.7
- Markdown==3.3.3
- Pillow>=7.1.0
- psycopg2==2.8.4
- redis==3.4.1
- requests==2.22.0
- nicorn==20.0.4
- flower==0.9.4
- pycryptodome==3.9.4
- python-dateutil==2.8.1
- responses==0.10.14

New derivations definitions:
- django-model-utils==4.0.0 (last : 4.1.1)
- environs==7.2.0 (last : 9.3.1)
- django-rename-app==0.1.2

we do not add dev dependencies
- coverage==5.1
- pytest-django==4.1.0
- pytest==6.1.2
- pytest-cov==2.10.1

## TODO

## Maybe

implements db backups (cf. postgres-docker from bookwyrm dist)


