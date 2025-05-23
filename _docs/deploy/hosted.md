---
title: Hosted Mode
category: Deploy
order: 5
---
# Hosted mode
- TOC
{:toc}

GyroidOS containers can also be run natively on your host, using the hosted mode.
This section describes how to run the hosted mode.
These instructions have been tested and work on Debian 13 Trixie.

## Requirements

Have a prebuilt container image ready or build one yourself as described in [Build](/build/build).

### Required packages
Install all required packages with the following command:
```
sudo apt update && sudo apt-get install -y git build-essential unzip re2c pkg-config \
    check lxcfs libprotobuf-c-dev automake libtool libselinux1-dev libcap-dev \
    protobuf-c-compiler libssl-dev udhcpd udhcpd libsystemd-dev debootstrap \
    squashfs-tools python3-protobuf protobuf-compiler \
    cryptsetup-bin iptables e2fsprogs
```

### Protobuf-c-text
To install protobuf-c-text, run the following commands:
```
git clone https://github.com/gyroidos/external_protobuf-c-text.git
cd external_protobuf-c-text/
./autogen.sh
./configure --enable-static=yes
make
sudo make install
sudo ldconfig
```

## Installation

### CML

> Requires OpenSSL version >= 3.2

Clone, compile and install the neccesary components with
```
git clone https://github.com/gyroidos/cml
cd cml/
SYSTEMD=y make -f Makefile_lsb
sudo SYSTEMD=y make -f Makefile_lsb install
```

### Additional tools
Clone and install the necessary components with
```
git clone https://github.com/gyroidos/gyroidos_build
cd gyroidos_build/cml_tools
sudo make install
```

## Setup

### Automatic

Download and run the [setup script](/assets/hosted-setup.sh) to automatically perform the steps outlined below.

### Manually

1. Create the log directory `/var/log/cml/`
2. Run `sudo cml-scd` once to create certificates
3. Create the `cml-control` group and add the current user to it
4. Create test certificates with `cml_gen_dev_certs /path/to/dir`. Note that the `/path/to/dir` directory should not exist.
5. Copy the `/path/to/dir/ssig_rootca.cert` to `/var/lib/cml/tokens/`
6. Start the `cmld` systemd service


## Guest OS Setup

### Automatic

Download and run the [guest setup script](/assets/hosted-debian-guest.sh), which automatically creates and starts a Debian 12 container.

### Manual

1. Create a folder for the Guest OS (`$BASE`)
2. Initialize the folder and generate a basic configuration with `cml_build_guestos init $GUEST_NAME --pki /path/to/dir`
3. Create a new rootfs using, e.g. `debootstrap`
4. Add the rootfs to an uncompressed tarball named `${GUEST_NAME}os.tar`
5. Move the tar ball into the `rootfs/` directory that was created in step 2
6. Build the Guest OS with `cml_build_guestos build $GUEST_NAME`
7. Create a new directory called `operatingsystems/<system-architecture>/`, replace `<system-architecture>` with `x86` or `arm`
8. Move `out/gyroidos-guests/${GUEST_NAME}os-1/` to `operatingsystems/<system-architecture>/`
9. Install the operating system with `cml-control push_guestos_config ${GUEST_NAME}os-1.conf ${GUEST_NAME}os-1.sig ${GUEST_NAME}os-1.cert`
10. In `/etc/cml/device.conf`, set
    - `signed_configs: false` to disable the signature verfication for development. This should **never** be done in production.
    - `update_base_url: "file://$BASE"`
11. Restart the `cmld` service
12. Confirm that the new Guest OS is detected by running: `cml-control list_guestos`
13. Create a GyroidOS container using its configuration file with `cml-control create conf/${GUEST_NAME}container.conf`
14. Update the container’s password (default is `"trustme"`) with `cml-control change_pin "$GUEST_NAME"`
15. Start the container with: `cml-control start "$GUEST_NAME"`. If the command returns `CONTAINER_START_EINTERNAL`, re-run the command.
16. Verify that the container is running by executing: `cml-control list "$GUEST_NAME"`
17. To access the container’s: `cml-control run $GUEST_NAME bash`

For additional details, see the [GuestOS configuration](/operate/guestos_config) and [Basic Operation](/operate/control) documentation pages.
