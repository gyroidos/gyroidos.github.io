#!/bin/bash
#
# This file is part of GyroidOS
# Copyright(c) 2013 - 2025 Fraunhofer AISEC
# Fraunhofer-Gesellschaft zur Förderung der angewandten Forschung e.V.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2 (GPL 2), as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GPL 2 license for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses/>
#
# The full GNU General Public License is included in this distribution in
# the file called "COPYING".
#
# Contact Information:
# Fraunhofer AISEC <gyroidos@aisec.fraunhofer.de>
#

set -euo pipefail

CERTS_DIR="${HOME}/test-certs"
GUEST_OS_DIR="${HOME}/cmld_guestos"
ROOTFS_DIR="rootfs-builder"
GUEST_NAME="guest-bookworm"
CONTAINER_NAME="${GUEST_NAME}container"

print() {
    echo
    echo "$*"
}

if [ ! -d "${CERTS_DIR}" ]; then
    print "Certificate directory '${CERTS_DIR}' is missing"
    exit 1
fi

# 0. Check if cmld is running
if ! systemctl status cmld.service | grep "Active: active"; then
    echo "cmld is not running."
    echo "Start cmld and re-run the script"
    exit 1
fi

# 1. Create and enter GuestOS directory
print "Creating GuestOS directory at ${GUEST_OS_DIR}"
mkdir "${GUEST_OS_DIR}"
cd "${GUEST_OS_DIR}"

# 2. Initialize guest OS
print "Initializing guest OS '${GUEST_NAME}'"
printf "y\n" | cml_build_guestos init "${GUEST_NAME}" --pki "${CERTS_DIR}"

# 3. Create Debian 12 rootfs
print "Creating Debian 12 rootfs"
mkdir "${ROOTFS_DIR}"
sudo debootstrap bookworm "${ROOTFS_DIR}" "http://deb.debian.org/debian"

# Create tar archive of rootfs
print "Creating tar archive of rootfs"
sudo tar -cf "${GUEST_NAME}.tar" -C "${ROOTFS_DIR}" .
mkdir -p rootfs
mv "${GUEST_NAME}.tar" rootfs/"${GUEST_NAME}os.tar"

# Build the guest OS
print "Building the guest OS '${GUEST_NAME}'"
sudo cml_build_guestos build "${GUEST_NAME}"

# Preparing to install the operating system
print "Preparing to install the operating system"
mkdir -p operatingsystems/x86/
sudo mv out/gyroidos-guests/guest-bookwormos-1/root.* operatingsystems/x86/

# Installing operating system
print "Installing operating system"
cml-control push_guestos_config out/gyroidos-guests/guest-bookwormos-1.conf out/gyroidos-guests/guest-bookwormos-1.sig out/gyroidos-guests/guest-bookwormos-1.cert

# Disable signed configs
print "Disabling signed configs for this example"
if ! grep -q "signed_configs" /etc/cml/device.conf; then
    echo "signed_configs: false" | sudo tee -a /etc/cml/device.conf > /dev/null
fi

# Restart cmld service, for some reason `systemctl restart cmld` does not work
print "Restarting cmld service"
sudo systemctl stop cmld.service
sleep 1
sudo systemctl start cmld.service
print "Verifying that cmld service restarted successfully"
if ! systemctl is-active --quiet cmld.service; then
    echo "cmld service failed to start"
    exit 1
fi

# Verify guest OS registration
print "Verifying that the guest OS was successfully registered"
if ! cml-control list_guestos | grep -q "${GUEST_NAME}"; then
    echo "Guest OS '${GUEST_NAME}' registration verification failed"
    exit 1
fi

# Create GyroidOS container
print "Creating GyroidOS container '${CONTAINER_NAME}'"
cml-control create "conf/${CONTAINER_NAME}.conf"

# Update container password to be empty
print "Updating container password to be empty"
printf "trustme\n\n\n" | cml-control change_pin "${CONTAINER_NAME}"

# Start the container
print "Starting the container '${CONTAINER_NAME}'"

while true; do
    STATE=$(printf "\n" | cml-control start "$CONTAINER_NAME")

    if $(echo "$STATE" | grep -q "CONTAINER_START_OK"); then
        echo "Container has started"
        break
    elif $(echo "$STATE" | grep -q "CONTAINER_START_EEXIST"); then
        echo "Container already exists"
        break
    fi
    
    echo "Container has not been started: $STATE. Waiting for 2 seconds before retrying"
    sleep 2
done

# Wait for the container to be running
print "Waiting for the container to be ready"
while true; do
    STATE=$(cml-control list "${CONTAINER_NAME}" | grep "state:")

    if $(echo "$STATE" | grep -q "RUNNING"); then
        echo "Container is running"
        break
    elif $(echo "$STATE" | grep -q "STOPPED"); then
        echo "Container has stopped. An error has occurred."
        exit 1
    else
        echo "Container is not yet running: $STATE. Waiting for 5 seconds before retrying"
        sleep 5
    fi
done

# Determine container's PID
print "To connect to the container, run:"
echo "cml-control run $GUEST_NAME bash"
