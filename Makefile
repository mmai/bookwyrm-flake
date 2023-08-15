update:
	nix flake lock --update-input nixpkgs
local:
	cd container && nix flake lock --update-input bookwyrm && cd -
	sudo nixos-container destroy bookwyrm
	sudo nixos-container create bookwyrm --flake ./container/
	sudo nixos-container start bookwyrm
root:
	sudo nixos-container root-login bookwyrm
