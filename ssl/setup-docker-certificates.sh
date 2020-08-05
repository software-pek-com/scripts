#!/bin/bash

# Configuring Docker to use TLS **WITHOUT** systemd socket
# https://docs.docker.com/engine/reference/commandline/dockerd//#daemon-configuration-file

echo '{
  "hosts": [
    "fd://",
    "tcp://0.0.0.0:2376"
  ],
  "tls": true,
  "tlscacert": "/etc/docker/ssl/ca.pem",
  "tlscert": "/etc/docker/ssl/server-cert.pem",
  "tlskey": "/etc/docker/ssl/server-key.pem",
  "tlsverify": true
}' | sudo tee /etc/docker/daemon.json

# Disable systemd docker host configuration
sudo mkdir -p /etc/systemd/system/docker.service.d
echo '[Service]
ExecStart=
ExecStart=/usr/bin/dockerd' | sudo tee /etc/systemd/system/docker.service.d/docker.conf
sudo systemctl daemon-reload
sudo service docker restart