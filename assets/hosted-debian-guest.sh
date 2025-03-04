#!/bin/bash

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

# Move guest OS to the operating systems directory
print "Moving guest OS to '/var/lib/cml/operatingsystems'"
sudo cp -r out/gyroidos-guests/* /var/lib/cml/operatingsystems

# Disable signed configs
print "Disabling signed configs for this example"
echo "signed_configs: false" | sudo tee -a /etc/cml/device.conf > /dev/null

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
print "Determining container's PID"
CONTAINER_PID=$(ps auxf | grep -A 10 "[/]usr/sbin/cmld" | grep /sbin/init | awk '{print $2}')
if [ -z "${CONTAINER_PID}" ]; then
    print "Failed to determine container's PID"
    exit 1
fi

print "To connect to the container, run:"
echo "sudo nsenter -at ${CONTAINER_PID}"
