---
title: Base System
category: Build
order: 3
---

# Build GyroidOS
- TOC
{:toc}

The steps to build GyroidOS are very similar for each flavour of the platform such as core, IDS, etc. The difference between these flavours are the containers installed on GyroidOS. In order to build the GyroidOS flavour you're interested in, select the appropriate containers in [the corresponding build step](#include-containers-to-gyroidos-image).
If you just want to try out GyroidOS the core flavour is the best option for you.

> Some build steps are architecture / device dependent. These steps are only necessary for that specific architecture / device.

## Prerequisites

The following prerequisites are necessary for **all** GyroidOS flavours. Please make sure your build host meets these requirements:
   * Build host configuration as described in section [Setup Host](/build/setup_host)
   * Sufficient hard disk space, at least 100 GB
   * Sufficient RAM. We tested the build on a VM having 4 GB RAM. However, a build host with less RAM should also work.

## Create a workspace directory
```
mkdir ws-yocto
cd ws-yocto
```

## Initialize workspace
Workspace initialization is done using the **repo** tool and the manifest file for the architecture you want to build for.
Please refer to the following list to select the correct manifest file:

|Manifest file | Description |
|--------------|---------------------------|
|**yocto-x86-genericx86-64.xml**|Any x86 based plattform supporting UEFI
|**yocto-arm32-raspberrypi2.xml**|Raspberry Pi2
|**yocto-arm64-raspberrypi3-64.xml**|Raspberry Pi3
|**yocto-arm64-tqma8mpxl-mba8mpxl.xml**|TQ-Systems TQMa8MPxL on MBa8MPxL SBC

```
repo init -u https://github.com/gyroidos/gyroidos.git -b kirkstone -m <manifest file>
repo sync -j8
```

## Setup yocto environment
In this step the necessary Yocto layers for your build are added and the bitbake command becomes available. 
Therefore, you have to specify the target architecture and machine for your build.
The following architectures and devices are supported currently:

|Architecture|Machine|
|----|---------------|
|x86| genericx86-64|
|arm32|raspberrypi2|
|arm64|raspberrypi3|
|arm64|tqma8mpxl|

```
source init_ws.sh out-yocto <architecture> <machine>
```
> This automatically switches to out-yocto

> **Note**: In order to build images for Freescale/NXP based SoCs (e.g. TQMa8MPxL), you need to accept the Freescale EULA by placing the line `ACCEPT_FSL_EULA = "1"` in `out-yocto/conf/local.conf`.

## Optional: Use own PKI
If you want to use your own PKI, place the necessary files into the directory `ws-yocto/out-yocto/test_certificates`.
For more information on which files are needed, please refer to the [PKI section](/pki).

<!--
## Build PMU firmware
> Xilinx ZCU104 specific

The ZCU104 board needs a fimware file for it's PMU. Run the following command to generate this file:
```
bitbake multiconfig:pmu:pmu-firmware
```
-->

## Include containers to GyroidOS image
These commands install guest operating systems and containers (e.g. the IDS container) to your GyroidOS platform.
In order to make GyroidOS work out of the box, use exactly **one** of the following commands.
Experienced users may choose to include all containers. However this will require manual configuration of the platform.

Build and include the minimal core container
```
bitbake multiconfig:container:trustx-core
```

Build and include the IDS Trusted Connector container
```
bitbake multiconfig:container:ids
```

Build and include the debian/os installer image (see [example: Using GuestOs debos](/operate/examples/#example-using-guestos-debos))
```
bitbake multiconfig:container:deb
```

> **experimental**:
Build and include the docker-converter image
(see [example: Using docker-convertos](/operate/examples/#example-using-docker-convertos))
```
bitbake multiconfig:container:docker-convert
```

## Build GyroidOS image
This step builds all necessary packages needed for GyroidOS and generates a bootable image that can be deployed to the boot medium of your platform.
In order to do so, please refer to the [Deploy section](/deploy/x86)

```
bitbake trustx-cml
```
## Build installer image
If required, a bootable installer image can be created. This image can be used to boot the target platform and install GyroidOS on the internal disk as described in the [Deploy section](/deploy/x86)
> Currently, the installer medium is only available for x86 platforms

```
bitbake multiconfig:installer:trustx-installer
```


## Build keytool image for UEFI Secure Boot configuration
> x86 UEFI specific

Create a bootable image containing the KeyTool and the GyroidOS secure boot keys.
This image can be used to configure secure boot on your platform as described in section [Deploy](/deploy/x86).
```
bitbake trustx-keytool
```


# Build FAQ
## How to change kernel config
#### Temporarily
```
bitbake -f -c menuconfig virtual/kernel
bitbake -f virtual/kernel
bitbake -f trustx-cml-initramfs
```

#### Persistently
The GyroidOS build system applies some kernel config fragments to the defconfig of your chosen ARCH by default.
After setting up the yocto environment the fragments are located in subdirectories of ```<ws>/trustme/build/yocto/```.

The following subdirectories contain the actual fragments which are applied in the same order as they are listed below:
* generic/fragments
* ARCH/fragments
* ARCH/DEVICE/fragments

If you wish to modify the kernel config permanently you may add a kernel config fragment file.
Keep the ordering of the fragment application in mind to ensure no intended changes get overwritten by defaults.

## How to sign kernel+initramfs binary manually
> x86 UEFI specific

```
sbsign --key test_certificates/ssig_subca.key \
      --cert test_certificates/ssig_subca.cert \
      --output linux.sigend.efi \
      ws-yocto/out-yocto/tmp/deploy/images/genericx86-64/cml-kernel/bzImage-initramfs-igenericx86-64.bin
```

In order to boot the signed kernel using UEFI, it should be placed as /EFI/BOOT/BOOTX64.EFI on the UEFI system partition.
