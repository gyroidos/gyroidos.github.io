---
title: QEMU/KVM
category: Deploy
order: 1
---


# Run GyroidOS image in QEMU/KVM (x86-64)
- TOC
{:toc}
Before following these steps you need to create the partitioned GyroidOS image as described in [Build]({{ "/" | absolute_url }}build/build)  
or download a released image from Github.

> **Current pre-built release image**: \\
[trustmeimage-{{site.release_tag}}_x86_trustx-corei7-64.img.bz2]({{site.githuborg}}/{{site.repository}}/releases/download/{{site.release_tag}}/trustmeimage-{{site.release_tag}}_x86_trustx-corei7-64.img.bz2) \\
[trustmeinstaller-{{site.release_tag}}_x86_trustx-corei7-64.img.bz2]({{site.githuborg}}/{{site.repository}}/releases/download/{{site.release_tag}}/trustmeinstaller-{{site.release_tag}}_x86_trustx-corei7-64.img.bz2)


In first place, you need to install QEMU/KVM and OVMF UEFI.
> **Note for Ubuntu users:** With the ovmf packet from the Ubuntu
repositories the GyroidOS image won't start.
Download the debian buster packet here: [packages.debian.org/buster/all/ovmf/download](https://packages.debian.org/buster/all/ovmf/download) and install it via dpkg.

```
apt-get install qemu-kvm ovmf
```
Also, an image holding the created containers is needed. Choose the image size large enough to hold the containers you will create.
```
dd if=/dev/zero of=containers.btrfs bs=1M count=<space to be available for containers>
mkfs.btrfs -L containers containers.btrfs
```
> When running consecutive tests with different builds make sure you use  a clean "containers.btrfs" image each time!

Now the GyroidOS image can be booted as follows:   
```
kvm -m 4096 -bios OVMF.fd -serial mon:stdio \
    -device virtio-rng-pci \
    -device virtio-scsi-pci,id=scsi \
    -device scsi-hd,drive=hd0 -drive if=none,id=hd0,file=tmp/deploy/images/genericx86-64/gyroidos_image/gyroidosimage.img,format=raw \
    -device scsi-hd,drive=hd1 -drive if=none,id=hd1,file=containers.btrfs,format=raw
```

# Use TPM emulation

This section describes the process of running GyroidOS in KVM/QEMU connected to an emulated TPM2.0
([swtpm](https://github.com/stefanberger/swtpm)) which runs inside a Docker container.

## Build SW-TPM Docker


```
cd ws-yocto/gyroidos/cml/tpm2d/swtpm-docker
docker build -t swtpm-docker .
```

## Run TPM 2.0 emulator in a Docker container

```
./run-swtpm-docker.sh
```

This creates a UNIX socket in the host's directory '/tmp/swtpmqemu/', which QEMU can connect to.

## Run KVM/QEMU

The following example runs a GyroidOS image using the TPM emulator and enabling host-guest port forwarding in KVM:

```
kvm -m 4096 -bios OVMF.fd -serial mon:stdio \
    -device virtio-rng-pci \
    -device virtio-scsi-pci,id=scsi \
    -device scsi-hd,drive=hd0 -drive if=none,id=hd0,file=tmp/deploy/images/genericx86-64/gyroidos_image/gyroidosimage.img,format=raw \
    -device scsi-hd,drive=hd1 -drive if=none,id=hd1,file=containers.btrfs,format=raw \
    -net nic -net user,hostfwd=tcp::8181-:8181,hostfwd=tcp::2323-:22 \
    -chardev socket,id=chrtpm,path=/tmp/swtpmqemu/swtpm-sock \
    -tpmdev emulator,id=tpm0,chardev=chrtpm \
    -device tpm-tis,tpmdev=tpm0
```

# Secure Boot Configuration

### prerequisites
We assume you have built the keytool image, see [build](/build/build#build-keytool-image-for-uefi-secure-boot-configuration).     
Further, we require the OMVF images from the build folder:
- `tmp/deploy/images/genericx86-64/ovmf.secboot.code.qcow2`
- `tmp/deploy/images/genericx86-64/ovmf.vars.qcow2`

## Set Platform keys in OVMF

The `ovmf.secboot.code.qcow2` image contains the actual firmware and must be
set read-only. The `ovmf.vars.qcow2` image provides a writable flash image for
efivars which will persist the secure boot keys.

```
kvm -m 4096 -serial mon:stdio \
    -device virtio-rng-pci \
    -device virtio-scsi-pci,id=scsi \
    -drive if=pflash,format=qcow2,readonly,file=out-yocto/tmp/deploy/images/genericx86-64/ovmf.secboot.qcow2 \
    -drive if=pflash,format=qcow2,file=out-yocto/tmp/deploy/images/genericx86-64/ovmf.vars.qcow2 \
    -device scsi-hd,drive=hd0 -drive if=none,id=hd0,file=tmp/deploy/images/genericx86-64/gyroidos_image/keytoolimage.img,format=raw
```
The KeyTool will be launched.
It should say:

    Platform is in Setup Mode
    Secure Boot is off

Use it to set the db and KEK keys
```
KeyTool -> Edit Keys
db -> Replace Key(s) -> efi -> keys/ -> DB.esl
KEK -> Replace Key(s) -> efi -> keys/ -> KEK.esl
```
Don't try to set the PK, this does not work with OVMF.
Exit the KeyTool
and the OVMF setup utility comes up. Set the PK there.
```
Device Manager -> Secure Boot Configuration -> Secure Boot Mode custom [Enter]
Custom Secure Boot Options -> PK Options -> Enroll PK -> Enroll PK Using File
   -> efi [...] -> <keys> -> PK.cer [Enter]
Commit Changes and Exit [Enter]
```
Exit the setup utility with `reset`.
This enables secure boot and the KeyTool will not show up again, since it is not
signed. You will drop in an EFI shell. The setup is complete and you can close
the QEMU instance.

## Run KVM/QEMU with Secure Boot
Now start the GyroidOS image as described above, however with the just
provisioned OVMF flash image.
```
kvm -m 4096 -serial mon:stdio \
    -device virtio-rng-pci \
    -device virtio-scsi-pci,id=scsi \
    -drive if=pflash,format=qcow2,readonly,file=tmp/deploy/images/genericx86-64/ovmf.secboot.code.qcow2 \
    -drive if=pflash,format=qcow2,file=tmp/deploy/images/genericx86-64/ovmf.vars.qcow2 \
    -device scsi-hd,drive=hd0 -drive if=none,id=hd0,file=tmp/deploy/images/genericx86-64/gyroidos_image/gyroidosimage.img,format=raw \
    -device scsi-hd,drive=hd1 -drive if=none,id=hd1,file=containers.btrfs,format=raw \
    -net nic -net user,hostfwd=tcp::8181-:8181,hostfwd=tcp::2323-:22 \
```

If the GyroidOS platform will not start and you find yourself in an EFI shell,
This could be because the QEMU DISK with the GyroidOS system was placed below
the EFI shell in the boot order. You can fix this in the EFI setup by just
exiting the EFI shell.
In the OVMF Setup menu select:

    Boot Maintenance Manager -> Boot Options -> Change Boot Order
    Move UEFI QEMU HARDDISK and UEFI QEMU HARDDISK 2 above UEFI PXEv4 and EFI Inernal Shell [Enter]
    Commit Changes and Exit [Enter]

