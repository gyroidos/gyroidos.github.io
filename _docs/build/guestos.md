---
title: Guest OS
category: Build
order: 4
---

# Create new Guest Operating Systems
- TOC
{:toc}

This page describes the process of creating a new guest OS to be used in GyroidOS containers.
It is possible to build a new guest OS using Yocto or by hand using a rootfs image. Both possibilities are described here.

## Using Yocto

This option mainly targets more advanced users. For information on Yocto, please refer to the [manual](https://www.yoctoproject.org/docs/current/mega-manual/mega-manual.html).  

### Preparing the build environment

First, your build host needs to be prepared as described in section [Setup Host](/build/setup_host)

For the purpose of building both the Base system and guest Operating Systems, follow the instructions provided in chapter [Build Base System](/build/build) and skip the rest of this subsection.

In order to setup an environment for building guest operating systems only, follow the steps below.

* Initialize and synchronize the repo:

```
repo init -u https://github.com/gyroidos/gyroidos.git -b kirkstone -m yocto-generic-container.xml
repo sync -j8
```

* Setup the environment specifying the target architecture:

```
source init_ws.sh out-yocto <architecture>
```
Currently supported architectures are: *x86*, *arm32*, and *arm64*.


### Create the image recipe

Each guest operating system image has a corresponding Yocto recipe file, *<custom-image-name>.bb*. The GyroidOS *meta-gyroidos* layer provides two standard image recipes:

* A core container image recipe, *\<yocto workspace directory\>/meta-gyroidos/images/gyroidos-core.bb*
* A service container image recipe, *\<yocto workspace directory\>/meta-gyroidos/images/gyroidos-service.bb*

To create a custom image you can either modify the existing image recipes or create your own ones in your meta-layer, using the provided recipes as templates. For the most cases the latter option is recommended. To use the existing recipe as a template for your own, just copy the recipe file to the target meta layer and rename it, e.g.:

```
cp <yocto workspace directory>/meta-gyroidos/images/gyroidos-core.bb <yocto workspace directory>/<target-meta-layer>/images/<custom-image-name>.bb
```

### (Optional) Create custom guest OS and container configs

For the guest operating system one can specify a custom guest OS and container configuration files, using the following definitions in the recipe file of the image:

* Guest operating system configuration template: *GUESTOS_CONF_TEMPLATE = "<path-to-config-file>"*
The specified config file will be used as a template, the guest operating system name will be automatically set to the recipe name: *<custom-image-name>os*

* Container configuration template: *CONTAINER_CONF_TEMPLATE = "<path-to-config-file>"*
The specified config file will be used as a template for the container hosting the operating system. The operating system for the container will be automatically set to the recipe name: *<custom-image-name>os*

In case the container or guest OS configs are not specified as described above, the standard templates will be used to create configuration files during the build process.

### Build guest OS image

At this point the new guest OS is ready for build and you can customize by adding and removing features, tailor the build process to your needs, etc.

You can build the image by calling the corresponding bitbake command:

```
bitbake multiconfig:container:gyroidos-<custom-image-name>
```

The image and configuration files will be located at *tmp_container/deploy/images/<architecture>/gyroidos-guests/* and *tmp_container/deploy/images/<architecture>/gyroidos-configs/container/*

If you are also building the core system from source, in order to include the new guest OS to your GyroidOS distro, also rebuild the core system image:
```
bitbake gyroidos-cml -cclean
bitbake gyroidos-cml
```

Now you can use the new guest OS when creating containers as described [here](/operate/control).

## Manually / Using a pre-built docker image
Prerequisites:
* The software signing certificate and key. If you use the auto-generated PKI the files needed are 'ssig.key' and 'ssig.cert'
* The signing scripts located at <yocto workspace directory>/gyroidos/build/device_provisioning/oss_enrollment/config_creator/
* A root file system image, in the following called root.img (e.g. created using docker build + docker export)
* An example guest OS config, for example the config located at "\<yocto workspace directory\>/gyroidos/build/config_overlay/x86/gyroidos-coreos.conf" (see [GuestOS configuration](/operate/guestos_config))


Steps to manually create a guest OS

## Create rootfs using docker
1. Adapt the example guest OS config
	* Change the 'name' field to a name of your choice
	* (Optional) Adapt the 'mounts' entries to your needs.
	* Set the 'image_size'. 'image_sha1' and 'image_sha2_256' values to match your root.img
2. Sign the adapted guest OS config using the sign_config.sh script as follows:
```
./sign_config.sh <guest OS config> ssig.key ssig.cert
```
3. Copy the created files to to /data/cml/operatingsystems, e.g. the files gyroidos-customos-1.conf, gyroidos-customos-1.cert and gyroidos-customos-1.sig
4. Create a directory for your guest OS root.img, e.g. /data/cml/operatingsystems/gyroidos-customos-1
5. Copy your root.img to the newly created directory
6. Create a new container using your guest OS as described [Basic operation](/operate/control)

## Using Docker converter from local registry
This is described in [Example: Using docker-convertos](/operate/examples#example-using-docker-convertos)
