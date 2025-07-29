---
title: Setup Host
category: Build
order: 2
---

# Setup build environment
- TOC
{:toc}

This page describes how to setup the build environment for the GyroidOS system.
The instructions were tested on Debian Bookworm (x86-64).
You can either build GyroidOS natively on your host or use a preconfigured, Docker-based build environment.
Choose the option that best fits your requirements.

## Docker-based build environment
1. Install repo tool:
```
sudo apt-get install repo
```

2. Create and initialize workspace on host (for further information and available manifests see [build/initialize workspace](/build/build#initialize-workspace))
```
mkdir ~/ws-yocto
cd ~/ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b main -m <manifest file>.xml
repo sync -j8
```
3. Build Docker image
```
cd ~/ws-yocto/gyroidos/build/yocto/docker
docker build -t gyroidos-builder .
```
4. Start Docker
Please ensure you are logged in as a non-root user. Otherwise, bitbake will refuse to run. A tutorial on how to run docker as a normal user can be found [here](https://docs.docker.com/install/linux/linux-postinstall/)
```
cd ~/ws-yocto/gyroidos/build/yocto/docker
./run-docker.sh ~/ws-yocto
```
5. Follow build instruction from [Setup Yocto environment](/build/build#setup-yocto-environment) inside the Docker container


## Setup host natively

The GyroidOS build needs packages from main and contrib archive areas. If not already done so, enable contrib in your sources.list.

1. To setup your build host, install the following packages required for Yocto/Poky (see
[Yocto reference manual](https://docs.yoctoproject.org/kirkstone/ref-manual/system-requirements.html#required-packages-for-the-build-host))
```
apt-get install build-essential chrpath cpio debianutils diffstat file \
     gawk gcc git iputils-ping libacl1 liblz4-tool locales python3 \
     python3-git python3-jinja2 python3-pexpect python3-pip \
     python3-subunit socat texinfo unzip wget xz-utils zstd
```
2. Install additional required packages for repo tool and image signing
```
apt-get install repo python3-protobuf
```
