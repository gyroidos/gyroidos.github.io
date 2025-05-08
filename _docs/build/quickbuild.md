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
repo init -u https://github.com/gyroidos/gyroidos.git -b main \
    -m yocto-x86-genericx86-64.xml
repo sync -j8
source init_ws.sh out-yocto x86 genericx86-64
bitbake multiconfig:container:gyroidos-core
bitbake gyroidos-cml
bitbake gyroidos-keytool
```

In order to create a bootable installation medium for installing GyroidOS on an internal disk,
also execute the following command:
```
bitbake multiconfig:installer:gyroidos-installer
```

## Raspberry Pi5

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b main \
     -m yocto-arm64-raspberrypi5.xml
repo sync -j8
source init_ws.sh out-yocto arm64 raspberrypi5
bitbake multiconfig:container:gyroidos-core
bitbake gyroidos-cml
```

## Raspberry Pi4

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b main \
     -m yocto-arm64-raspberrypi4-64.xml
repo sync -j8
source init_ws.sh out-yocto arm64 raspberrypi4-64
bitbake multiconfig:container:gyroidos-core
bitbake gyroidos-cml
```

## Raspberry Pi3

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b main \
     -m yocto-arm64-raspberrypi3-64.xml
repo sync -j8
source init_ws.sh out-yocto arm64 raspberrypi3-64
bitbake multiconfig:container:gyroidos-core
bitbake gyroidos-cml
```

## Raspberry Pi2

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b main \
     -m yocto-arm32-raspberrypi2.xml
repo sync -j8
source init_ws.sh out-yocto arm32 raspberrypi2
bitbake multiconfig:container:gyroidos-core
bitbake gyroidos-cml
```

## TQ-Systems TQMa8MPxL

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b main \
     -m yocto-arm64-tqma8mpxl-mba8mpxl.xml
repo sync -j8
source init_ws.sh out-yocto arm64 tqma8mpxl
echo 'ACCEPT_FSL_EULA = "1"' >> conf/local.conf
bitbake multiconfig:container:gyroidos-core
bitbake gyroidos-cml
```

## BeagleV-Fire

```
mkdir ws-yocto
cd ws-yocto
repo init -u https://github.com/gyroidos/gyroidos.git -b main \
     -m yocto-riscv-beaglev-fire.xml
repo sync -j8
source init_ws.sh out-yocto riscv beaglev-fire
bitbake multiconfig:container:gyroidos-core
bitbake gyroidos-cml
```
