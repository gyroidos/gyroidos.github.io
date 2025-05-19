---
title: EWC 2025
category: Talks
order: 1
---


# Embedded Linux Security @ Embedded World Conference 2025
- TOC
{:toc}

## RaspberryPi Exercises

### Prerequisites
In order to participate in the RaspberryPi exercises, please make sure to install
the required tools to flash and control the RaspberryPi via a serial connection.
For these tasks we recommend the following tools:

- Windows users:
  - RaspberryPi Imager from [https://www.raspberrypi.com/software/](https://www.raspberrypi.com/software/)
  - PuTTY from [https://www.putty.org/](https://www.putty.org/)
- Linux users:
  - Flash using **dd** (installed by default)
  - Your favourite serial monitor (e.g. minicom)

The images that will be deployed to the RaspberryPi can be downloaded from:  
__[https://owncloud.fraunhofer.de/index.php/s/rEKf9FTHJZNlu8o](https://owncloud.fraunhofer.de/index.php/s/rEKf9FTHJZNlu8o)__  

Please download and extract these images:
- keyimage.img.xz
- gyroidosimage.img.xz

### Establish a Serial Connection
We will control the RaspberryPi via a serial connection. Plug the USB-to-Serial
Adapter into your Laptop and start a serial monitor:

- Linux
```
minicom -b 115200 -D /dev/ttyUSB0
```
- Windows
  - Open PuTTY, establish a serial connection with a baudrate of 115200 to the 
    appropriate COM-Port.
  - The COM-Port can be found by (un)plugging the USB-to-Serial adapter and identifying
    the new COM-Port.

### Deploy the Secure Boot Key
We provide a pre-built image (keyimage.img.xz) that, when copied to the SD-Card
and run on the RaspberryPi, will update the Pi's SPI Flash with a _customer public
key_. A full reference and tutorial, how to deploy secure boot keys on the RaspberryPi
can by found [here](https://github.com/raspberrypi/usbboot/blob/master/secure-boot-recovery5/README.md).

After downloading and extracting the image, please flash the key image to the SD-Card:
- Linux
```
$ sudo dd if=keyimage.img of=/dev/<sd_card> status=progress
```
- Windows: Open the RaspberryPi and select the following parameters:
  - Model: RaspberryPi 5
  - OS: Use Custom: Select keyimage.img
  - SD-Card: select the inserted SD-Card

Insert the SD-Card into your RaspberryPi, and apply power. After a few seconds,
the green LED on your RaspberryPi should start blinking. This indicates that the
flash update was successful.

### Deploy GyroidOS
Redo the steps from above for gyroidosimage.img. Beware that due to its size,
flashing to the SD-Card can take a few minutes. After flashing the SD-Card, insert
it into your RaspberryPi and apply power.

Look at the serial output from the bootloader, you should see messages, indicating
that secure boot is enabled.

Once GyroidOS is booted, you can log in on the serial console as root using the
password 'root'. You are now in the GyroidOS development shell.

### Explore IMA on GyroidOS
On the development shell, navigate to `/sys/kernel/security/ima` and examine the
content of the following files: 
- `policy`
- `ascii_runtime_measurements`

### Full Disk Encryption (optional)
Have a look at the output of the `mount` command and look at the contents of
`/data/cml`. Then:
- shut down the RaspberryPi (type `poweroff`) and unplug from power
- pull off the TPM
- re-attach power

Now again, examine `mount` and `/data/cml`. What do you observe?

**NOTE: When re-attaching the TPM, make sure it is plugged in to the correct pins.
When in doubt, please ask one of us to verify the correct installation.**

