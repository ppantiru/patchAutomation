#!/usr/bin/env bash

install_docker (){
if ! command -v docker; then
        echo "Installing docker..."
	#sudo addgroup --system docker
	#sudo adduser $USER docker
	#newgrp docker
        #sudo snap install docker
	if [ "$(uname)" == "Darwin" ]; then
		# Install docker on Mac OS X platform
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		brew cask install docker
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
		# Install docker on GNU/Linux platform
		sudo apt install docker.io -y
		sudo usermod -aG docker $USER
	fi
	docker --version
else
        echo "Docker is already installed"
fi
}
