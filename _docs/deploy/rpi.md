---
title: "ARM: rpi"
category: Deploy
order: 3
---

# Deploy GyroidOS on Raspberry Pi platforms
- TOC
{:toc}

This section describes how to deploy GyroidOS on Raspberry Pi platforms.

> **Current pre-built release image**: \\
[trustmeimage-{{site.release_tag}}_arm32_raspberrypi2.img.bz2]({{site.githuborg}}/{{site.repository}}/releases/download/{{site.release_tag}}/trustmeimage-{{site.release_tag}}_arm32_raspberrypi2.img.bz2)\\
[trustmeimage-{{site.release_tag}}_arm64_raspberrypi3-64.img.bz2]({{site.githuborg}}/{{site.repository}}/releases/download/{{site.release_tag}}/trustmeimage-{{site.release_tag}}_arm64_raspberrypi3-64.img.bz2)

## Create bootable medium

### Requirements
* A successfully built GyroidOS image file (gyroidosimage.img), either downloaded from [Github Release]({{site.githuborg}}/{{site.repository}}/releases/tag/{{site.release_tag}}) or built following the instructions [here]({{ "/" | abolute_url }}build/build#build-gyroidos-image).
* The script **copy_image_to_disk_mbr.sh** which can be found [on GitHub](https://github.com/gyroidos/gyroidos/raw/main/yocto/copy_image_to_disk_mbr.sh) or in your build folder at `gyroidos/build/yocto/copy_image_to_disk_mbr.sh`
* A MicroSD card compatible with your board
* Optional: Bmap file `gyroidosimage.img.bmap` which is automatically created by the build system and deployed next to `gyroidosimage.img`. This enables flashing using [bmaptool](https://manpages.debian.org/testing/bmap-tools/bmaptool.1.en.html).


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
- **Raspberry Pi2**
```
cd ws-yocto # your yocto workspace directory
sudo copy_image_to_disk_mbr.sh \
	out-yocto/tmp/deploy/images/raspberrypi2/gyroidos_image/gyroidosimage.img \
	/dev/mmcblk0
```
- **Raspberry Pi3**
```
cd ws-yocto # your yocto workspace directory
sudo copy_image_to_disk_mbr.sh \
	out-yocto/tmp/deploy/images/raspberrypi3-64/gyroidos_image/gyroidosimage.img \
	/dev/mmcblk0
```
- **Raspberry Pi4**
```
cd ws-yocto # your yocto workspace directory
sudo copy_image_to_disk_mbr.sh \
	out-yocto/tmp/deploy/images/raspberrypi4-64/gyroidos_image/gyroidosimage.img \
	/dev/mmcblk0
```
- **Raspberry Pi5**
```
cd ws-yocto # your yocto workspace directory
sudo copy_image_to_disk_mbr.sh \
	out-yocto/tmp/deploy/images/raspberrypi5/gyroidos_image/gyroidosimage.img \
	/dev/mmcblk0
```

## Boot GyroidOS

Connect a monitor to the HDMI port and a keyboard to the USB connector of your Raspberry Pi
 board.

After boot a shell in the management container (c0) will be available at tty1.
Also a debug shell into the CML will be available at tty12.
Further, the init log messages will appear on tty11.

> **Note**: On first boot several keys are generated, thus it may take a long
time untill login prompt may appear. You can accelerate the progress by generating
randomness with the connected keyboard.

For instructions on how to operate GyroidOS please refer to section [Operate](/operate/control).
