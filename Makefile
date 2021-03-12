update:
	nix flake update --update-input nixpkgs
tests:
	sudo nixos-container destroy bookwyrm
	sudo nixos-container create bookwyrm --flake ./test/
	sudo nixos-container start bookwyrm
	# sudo nixos-container root-login bookwyrm
