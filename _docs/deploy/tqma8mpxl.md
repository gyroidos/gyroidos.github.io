---
title: "ARM: TQMa8MPxL"
category: Deploy
order: 4
---

# Deploy GyroidOS on TQ-Systems TQMa8MPxL-MBa8MPxL
- TOC
{:toc}

This section describes how to deploy GyroidOS on the TQ-Systems TQMa8MPxL module
when mounted on the MBa8MPxL board.

## GyroidOS image
Build the GyroidOS image according to the instructions [here]({{ "/" | abolute_url }}build/build#build-gyroidos-image).
> **Note**: In order to build the image, you need to accept the Freescale EULA by placing the line `ACCEPT_FSL_EULA = "1"` in `out-yocto/conf/local.conf`.

## Create bootable medium
### Requirements
* A successfully built GyroidOS image file `trustmeimage.img`.
* The script **copy_image_to_disk_mbr.sh** which can be found [on GitHub](https://github.com/gyroidos/gyroidos/raw/master/yocto/copy_image_to_disk_mbr.sh) or in your build folder at `trustme/build/yocto/copy_image_to_disk.sh`
* A MicroSD card compatible with your board
* Optional: Bmap file `trustmeimage.img.bmap` which is automatically created by the build system and deployed next to `trustmeimage.img`. This enables flashing using [bmaptool](https://manpages.debian.org/testing/bmap-tools/bmaptool.1.en.html).

First, ensure the needed packages are installed on your system.
```
apt-get install util-linux btrfs-progs sgdisk parted bmap-tools
```

### Copy GyroidOS image to disk
Now the GyroidOS image can be copied to the MicroSD card.
The provided script takes care of expanding the partitions to use all of the available disk space.

**WARNING: This operation will wipe all data on the target device**
```
sudo copy_image_to_disk_mbr.sh <gyroidos-image> </path/to/target/device>
```

If you have built from source in `ws-yocto` and your target device is `/dev/mmcblk0` the command would be:
```
cd ws-yocto # your yocto workspace directory
sudo copy_image_to_disk_mbr.sh \
	out-yocto/tmp/deploy/images/tqma8mpxl-mba8mpxl/trustme_image/trustmeimage.img \
	/dev/mmcblk0
```

In this example, if the bmap file `out-yocto/tmp/deploy/images/tqma8mpxl-mba8mpxl/trustme_image/trustmeimage.img.bmap`
exists and bmaptool is installed, the script will automatically flash to the MicroSD card using the quick bmaptool.
If one of these requirements is not fulfilled `copy_image_to_disk_mbr.sh` will fall back to slower copy using dd.

## Boot GyroidOS
Connect your PC via a Micro-USB cable to connector X28 on the board.
This will create four serial interfaces, e.g.:
```
crw-rw---- 1 0 986 188, 0 19. Feb 11:32 /dev/ttyUSB0
crw-rw---- 1 0 986 188, 1 19. Feb 11:32 /dev/ttyUSB1
crw-rw---- 1 0 986 188, 2 19. Feb 11:32 /dev/ttyUSB2
crw-rw---- 1 0 986 188, 3 19. Feb 11:32 /dev/ttyUSB3
```

Connect to the CML debug shell via the highest interface, e.g. `ttyUSB3`.

For instructions on how to operate GyroidOS please refer to section [Operate](/operate/control).
