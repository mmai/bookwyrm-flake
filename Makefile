update-nixpkgs:
	nix flake update --update-input nixpkgs
local:
	cd container && nix flake update --update-input bookwyrm && cd -
	sudo nixos-container destroy bookwyrm
	sudo nixos-container create bookwyrm --flake ./container/
	sudo nixos-container start bookwyrm
root:
	sudo nixos-container root-login bookwyrm
