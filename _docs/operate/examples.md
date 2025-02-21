---
title: Examples
category: Operate
order: 4
---


# Example: Using GuestOS debos
- TOC
{:toc}
The GuestOS debos provides a basic integrity protected debian installer
base image. This GuestOS type provides the ability to setup a
confidential debian system inside a container.
In order to achieve that, we use the setup mode for running a container instance of debos.

### Prerequisites
* a running (deployed) GyroidOS system.
* configured internet access in core0 (default is dhcp on eth0)
* we assume a standard password for usertoken "trustme"
* an installed debos image in that system   

 You can verify that debos is installed by:
```
root@gyroidos-core:~# control list_guestos | grep debos
     name: "debos"
```

### Creating container and installing debian
create a new container config skeleton file `debian1.skel` for the container e.g.:
```
name: "debian1"
guest_os: "debos"
color: 0
vnet_configs {
    if_name: "eth0"
    configure: true
}
image_sizes {
    image_name: "enc_root"
    image_size: 8192
}
```
The images_size argument overwrites the standard size of the encrypted writable
data image which is mounted as rootfs in case of normal boot.

Create and start the container in setup mode:
```
control create debian1.skel
control start debian1 --key=trustme --setup
```
You can verify that the container has reached setup state by:
```
control state debian1
```
Now you can run commands inside the container to install
a standard Linux system to `/setup` inside the container.
The debos image contains a debootstrap util inside the container to
setup a debian system. However, you could also try to run any other
bootstrapping tool for another distribution, e.g., emerge. In that case,
you have to download the bootstrapper first, loosing integrity protection
of the installer. We proceed with `debootstrap`.
> Remember that control run is somewhat experimental and not all characters,
especially control characters like [Ctrl]+C, may work as expected.

```
control run debian1 /bin/bash
``` 
Now we are inside the container "debian1".   
You can check if the encrypted root is mounted on setup by calling `mount`

Install debian as follows:
```
export PATH=$PATH
debootstrap stretch /setup
printf '%s\n' '#!/bin/bash' '/sbin/cservice' 'exit 0' > /setup/etc/rc.local
chmod a+x /setup/etc/rc.local
exit
```
Now stop the container and start it normally:
```
control stop debian1
control start debian1 --key=trustme
```
 
# Example: Using docker-convertos
> **Experimental**, the converter may not work for every image on dockerhub!

### Prerequisites
* a running (deployed) GyroidOS system.
* an installed docker-convertos image in that system   
  You can verify this by checking:

    ```
    root@cml:~# control list_guestos | grep docker-convertos
    name: "docker-convertos"
    ```
* configured internet access in core0 (default is dhcp on eth0)
* we assume a standard password for usertoken "trustme"

### Creating converter container
Create a new container config skeleton file `docker2.skel` for the container e.g.:
```
name: "docker2"
guest_os: "docker-convertos"
color: 0
vnet_configs {
  if_name: "eth0"
  configure: true
}
image_sizes {
  image_name: "tmp"
  image_size: 8192
}
```

```
control run docker2 /bin/bash
```
Inside container:
```
export PATH=$PATH
/etc/init.d/lighttpd start
converter pull <dockerhub image> <tag>
/etc/init.d/lighttpd stop
exit
```

### Creating instance of converted image
```
control list_guestos
```
Should show new GuestOS created from Dockerhub image
with a name like "`<image>_<tag>_<timestamp>`"

Create a new config skeleton `/etc/templates/converted.skel` for the image:
```
name: "converted3"
guest_os: "<image>_<tag>_<timestamp>"
color: 0
vnet_configs {
  if_name: "eth0"
  configure: true
}
```

```
control create converted.skel
```
Run it.
```
control start converted3 --key=trustme
```
