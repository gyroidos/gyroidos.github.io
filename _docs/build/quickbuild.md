---
title: Quick Build
category: Build
order: 1
---

# Quick build instructions
* TOC
{:toc}

This section sums up the necessary steps to build GyroidOS on different architectures.
For a detailed explanation of each build step please refer to the [build section](/build/build)
and make sure [prerequisites](/build/build#prerequisites) have been met.


## x86 platforms
```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b kirkstone \
    -m yocto-x86-genericx86-64.xml
repo sync -j8
source init_ws.sh out-yocto x86 genericx86-64
bitbake multiconfig:container:trustx-core
bitbake trustx-cml
bitbake trustx-keytool
```

In order to create a bootable installation medium for installing GyroidOS on an internal disk,
also execute the following command:
```
bitbake multiconfig:installer:trustx-installer
```

## Raspberry Pi3

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b kirkstone \
     -m yocto-arm64-raspberrypi3-64.xml
repo sync -j8
source init_ws.sh out-yocto arm64 raspberrypi3-64
bitbake multiconfig:container:trustx-core
bitbake trustx-cml
```

## Raspberry Pi2

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b kirkstone \
     -m yocto-arm32-raspberrypi2.xml
repo sync -j8
source init_ws.sh out-yocto arm32 raspberrypi2
bitbake multiconfig:container:trustx-core
bitbake trustx-cml
```

## TQ-Systems TQMa8MPxL

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b kirkstone \
     -m yocto-arm64-tqma8mpxl-mba8mpxl.xml
repo sync -j8
source init_ws.sh out-yocto arm64 tqma8mpxl
echo 'ACCEPT_FSL_EULA = "1"' >> conf/local.conf
bitbake multiconfig:container:trustx-core
bitbake trustx-cml
```
