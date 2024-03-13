apply: update os home 

os: copy rebuild

home: copy.home rebuild.home

install:
	nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager
	nix-channel --update
	nix-shell '<home-manager>' -A install

copy.home:
	cp home.nix ~/.config/home-manager/home.nix

rebuild.home:
	home-manager build
	home-manager switch

copy:
	sudo cp configuration.nix /etc/nixos/configuration.nix

rebuild:
	sudo nixos-rebuild switch

grab:
	cp /etc/nixos/configuration.nix .

update:
	sudo nix-channel --update

cleanup:
	sudo nix-collect-garbage --delete-older-than 14d