---
title: CML Layer SSH Access
category: Operate
order: 6
---


# CML Layer SSH Access

- TOC
{:toc}

During the development process it may be convenient to access GyroidOS' root
namespace (CML layer) via a remotely accessible interface. This can assist tasks
like remote debugging or automated testing. Therefore, when building a
development image, the Yocto build system installs the openSSH server into the
CML layer which is then automatically started when the system boots.

All following commands are executed from Yocto's build directory:
```
$ cd ws-yocto/out-yocto
```

## Obtaining the SSH private key
The CML's root file system is not writable during operation, which prevents 
deploying an own SSH public key. For this reason development images contain a
pre-deployed public key that can be used to access the CML layer. This key and
its corresponding private key is can be found in the build artefacts of the
Yocto build:
```
$ ls tmp/deploy/images/genericx86-64/ssh-keys
id_ed25519  id_ed25519.pub  ssh_host_ed25519_key  ssh_host_ed25519_key.pub
```
Additionally, the pre-deployed host key of the CML layer is provided.

## Forwarding host port to virtual machine
As per design GyroidOS' root namespace is not accessible from a network outside
of GyroidOS. To make the CML's SSH port publicly accessible, port 2222 of the c0
container is forwarded to port 22 of the root namespace. Using this port one can
connect to the CML layer via SSH.

For this example, we assume GyroidOS is running as a KVM virtual machine set up
according to our [guidelines](/deploy/qemu). QEMU uses
[SLIRP User Networking](https://wiki.qemu.org/Documentation/Networking#User_Networking_(SLIRP))
which does not expose the guest VM's network interface to the host, therefore
c0's port 2222 must be made accessible from the host via another port forward.
Add the parameter `-nic user,hostfwd=tcp::2222-:2222` to the QEMU command, to
forward the hosts port 2222 to c0's port 2222. Run the GyroidOS VM using
```
$ qemu-system-x86_64 -enable-kvm -m 4096 -serial mon:stdio \
    -bios OVMF.fd \
    -device virtio-rng-pci \
    -device virtio-scsi-pci,id=scsi \
    -device scsi-hd,drive=hd0 -drive if=none,id=hd0,file=ws-yocto/out-yocto/tmp/deploy/images/genericx86-64/gyroidos_image/gyroidosimage.img,format=raw \
    -device scsi-hd,drive=hd1 -drive if=none,id=hd1,file=containers.ext4,format=raw \
    -nic user,hostfwd=tcp::2222-:2222
```

## Create SSH known_hosts file
To verify the connection to your GyroidOS instance and not to pollute your hosts
`~/.ssh/known_hosts` file, create a temporary `known_hosts` file from the host
public key of GyroidOS that also gets deployed by the build system:
```
$ echo "[localhost]:2222 $(cat tmp/deploy/images/genericx86-64/ssh-keys/ssh_host_ed25519_key.pub)" > known_hosts
```

## Connect to the CML layer
Using the public key provided by the yocto build system and the generated
`known_hosts` file, it is now possible to connect to GyroidOS' root namespace 
using
```
$ ssh \
    -p 2222 \
    -i tmp/deploy/images/genericx86-64/ssh-keys/id_ed25519 \
    -o "UserKnownHostsFile known_hosts" \
    root@localhost
root@cml:~#
```
