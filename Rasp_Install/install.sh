#!/bin/bash
# Script di setup completo Raspberry Pi 4 per Docker stack

echo "Aggiornamento sistema..."
sudo apt update && sudo apt upgrade -y

echo "Installazione pacchetti necessari..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

echo "Installazione Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

echo "Installazione Docker Compose..."
sudo apt install -y libffi-dev libssl-dev python3 python3-pip
sudo pip3 install docker-compose

echo "Creazione cartelle per docker-compose..."
mkdir -p ~/docker/{ha/config,nginx/data,nginx/letsencrypt,duckdns/config,radarr/config,prowlarr/config,media/movies,downloads,hyperion/config,backups}

echo "Installazione completata! Riavvia il sistema prima di usare Docker."
echo "Dopo il riavvio, puoi lanciare lo stack con: docker-compose up -d"
