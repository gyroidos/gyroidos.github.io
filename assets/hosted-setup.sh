#!/bin/bash

print() {
    echo
    echo "$*"
}

set -euo pipefail

GROUP_NAME="cml-control"
CERTS_DIR=~/test-certs

# Create and add user to the cml-control group
if $(groups | grep -q "$GROUP_NAME"); then
    echo "Group '$GROUP_NAME' already exists"
else
    echo "Creating cml-control group"
    sudo addgroup cml-control
fi

if $(id | grep -q "$GROUP_NAME"); then
    echo "User is already in the '$GROUP_NAME' group"
else
    echo "Adding current user to group"
    sudo usermod -aG cml-control $(whoami)
    echo "Reloading groups, you may need to re-run the script to continue."
    (newgrp "$GROUP_NAME")
fi

# Create the logging directory
print "Creating log directory"
sudo mkdir -p /var/log/cml/cml-scd

# Creating tokens
if [ -d "/var/lib/cml/tokens/" ] && [ ! -z "$(ls -A '/var/lib/cml/tokens/')" ]; then
    echo "Using existing tokens"
else
    echo "Initalizing tokens"
    sudo cml-scd
fi

# Calling `cml_gen_dev_certs` on an existing directory does not create any certificates
if [ -d $CERTS_DIR ]; then
    echo "Remove the directory at '$CERTS_DIR' and re-run the script"
    exit 1
fi

# Creating cml certificates
print "Creating root certificates"
cml_gen_dev_certs $CERTS_DIR

print "Installing root certificates"
sudo cp $CERTS_DIR/ssig_rootca.cert /var/lib/cml/tokens/

print "Starting cmld.service"
sudo systemctl start cmld.service

print "Waiting for the service to start"
sleep 2
if $(systemctl is-active --quiet cmld.service); then
    echo "Starting the service was successful."
    echo "You're good to go"
else
    echo "Starting the service failed"
    echo "Run 'systemctl status cmld.service' for more information"
fi

