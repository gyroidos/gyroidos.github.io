---
title: Container configuration
category: Operate
order: 2
---


# Container configuration
- TOC
{:toc}

All containers currently available are defined in the configuration files in the form `<container-uuid>.conf` in the '/data/cml/containers/' folder. The `<container-uuid>` is a Universal Unique Identifier provided in five character groups separated by hyphens, e.g., 11111111-1111-1111-1111-111111111111.

## Container configuration management
Accessing those files directly is not possible from core0 container.
Only in development builds with enabled `'debug-tweeks'`, you can access this
through debugging CML shell on tty12.
Intended control of container configuration is gained through the control interface from within
core0 container.
The corresponding commands of the control tool are `create`, `config` and `update_config`

**create** uses a container.config skeleton as shown above, and writes it to corresponding
config files in `/data/cml/containers/` with a random uuid. The corresponding created config
is also responded back to core0 through the control interface.
> Note that the CML may modify certain fields of the provided configuration, such as the ```if_rootns_name```, if necessary.

**config** requests the configuration from an existing container. Similar to
the answer of create. You can write it to some location inside core0 to edit it.

**update_config**  writes back an edited config or just overwrites the existing
config by the provided skeleton.


## Container configuration specification

A full container configuration file includes the following (optional) fields:

```
// user configurable, non unique
required string name
// name of GuestOS, e.g. idsos
required string guest_os
// (minimal) version of GuestOS
// will be updated if container is started with a more recent GuestOS version.
optional uint64 guestos_version
// complete image sizes from GuestOS for user partitions
repeated ContainerImageSize image_sizes
// ram limit of container, set ram_limit to 0 for unlimited ram
optional uint32 ram_limit [ default = 0 ];      // unit = MBytes
required fixed32 color
// type of container, e.g. KVM or CONTAINER
required ContainerType type [ default = CONTAINER ]
repeated string init_env	// environment variables
// use user_namespace
optional bool userns [default = true]
// Flags indicating the allows for containers:
optional bool allow_autostart [default = false]
// a list of strings wich contain the features image prefix name without .img
repeated string feature_enabled
optional string dns_server
optional bool netns [default = true]
// a list of network interfaces assigned to this container
repeated string net_ifaces
// a list of devices explicitely allowed for this container
repeated string allow_dev
// a list of devices exclusively assigned to this container
repeated string assign_dev
// list of virtual network interface configuration
repeated ContainerVnetConfig vnet_configs
// list of usb devices assigned to this container
repeated ContainerUsbConfig usb_configs
// number of pipes from c0 to this container
repeated string fifos
// Specifies the container token type, e.g. NONE, SOFT or USB
required ContainerTokenType token_type [ default = SOFT ];
// Specifies that an external USB pin reader device is to be used for pin entry on container start and stop
optional bool usb_pin_entry [ default = false ];
}
```

The full-blown protocol specification can be found [here](https://github.com/gyroidos/cml/blob/main/daemon/container.proto) as protobuf-text formatted file.


### Parameter image_sizes
The ```image_sizes``` parameter defines the sizes of user partitions of the GuestOS. Its type ```ContainerImageSize``` is defined as follows:

```
message ContainerImageSize {
	required string image_name = 1; // virtual name of the image file in guestos
	required uint64 image_size = 2; // size (Mbytes) of the image file
	optional string image_file = 3; // name of alternate image file which overwrites image_name of guestos config
}
```
Valid configuration depends on the choice of the [GuestOS configuration](/operate/guestos_config) and its ```mounts``` parameters.
For example, the ```debos```  GuestOS configuration defines
```
mounts {
	image_file: "enc_root"
	mount_point: "/"
	fs_type: "ext4"
	mount_type: EMPTY
}
```
and therefore, a container configuration that includes the ```debos``` GuestOS
may include
```
image_sizes {
	image_name: "enc_root"
	image_size: 8192
}
```
to increase the size of the mount named "enc_root" from its default size defined in the GuestOS configuration to 8GiB.

### Parameter net_ifaces
The repeated ```net_ifaces``` parameter list host network interfaces that are assigned to the container. The interfaces are identified by their name as it is printed the ``` ip link``` command. Aternatively a hex representation of the MAC address like `00:11:22:33:44:55` could be used.

### Parameter allow_dev and assign_dev
The repeated ```allow_dev``` parameter list host devices which the container is allowed to access.
The repeated ```assign_dev``` parameter list host devices which the container is allowed to access.
Devices are identified using the **cgroups** syntax.

### Parameter vnet_configs
The repeated ```vnet_configs```parameter list virtual network interface configuration.
They are of type ```ContainerVnetConfig``` which is defined as

```
message ContainerVnetConfig {
	required string if_name = 1; // name of virtual veth endpoint in container
	required bool configure = 2; // should cmld configure the interface or leav it unconfigured
	optional string if_rootns_name = 3; // name of virtual veth endpoint in rootns (will be autogenerated by cmld)
	optional string if_mac = 4; // mac of virtual veth endpoint inside container (will be autogenerated)
}
```

### Parameter usb_configs
The repeated ```usb_config``` parameter lists host USB devices which are assigned to the container.
Their type is

```
message ContainerUsbConfig {
	required string id = 1;
	required string serial = 2;
	required bool assign = 3 [default = false];
	required ContainerUsbType type = 4 [default = GENERIC];
}
```
The USB devices are identified by their major and minor number and their serial number. The necessary information can be found e.g by first identifying the number of the USB bus and the device number using the ```lsusb``` command.
Using this information ```udevadm info /dev/bus/usb/<BUS_NR>/<DEV_NR>``` yields the desired information.

The ContainerUsbType is

```
enum ContainerUsbType {
	GENERIC = 1;
	TOKEN = 2;
	PIN_ENTRY = 3;
}
```

The type `TOKEN` is used for USB-tokens. `PIN_ENTRY` devices are external pin reader usb devices
that must be used for pin entry e.g. on container start and stop if specified. All other devices
are `GENERIC`.

An example for a valid ```usb_configs``` entry may look like this:
```
usb_configs {
	id: "0x17ef:0x306c"
	serial: "11AD1D009C9449100D8900B00"
	assign: true
	type: GENERIC
}
```

### Parameter fifos
The GyroidOS architecture enables the usage of unidrectional communication channels which can be used to transfer information from c0 to other containers but inhibits any information leakage from the containers.
This feature can be used e.g. to inject external information on network state, such as DNS entries, from c0 into a container.
The CML creates one Linux fifo for each ```fifos``` entry which are accessible under ```/dev/cfifos```.


## Example container configuration

The following example depicts a run-time configuration which includes two virtual Ethernet interfaces and one USB device assigned to the container:

```
name: "core0"
guest_os: "debos"
guestos_version: 1
color: 0
type: CONTAINER
image_sizes {
	image_name: "enc_root"
	image_size: 8192
}
vnet_configs {
	if_name: "eth0"
	configure: false
	if_rootns_name: "r_0"
	if_mac: "62:96:af:ab:7d:56"

}
vnet_configs {
	if_name: "eth1"
	configure: false
	if_rootns_name: "r_1"
}
usb_configs {
  id: "04e6:5816"
  serial: "5511747600021"
  assign: true
  type: GENERIC
}
assign_dev: "c 4:1 rwm"
allow_dev: "c 116:1 rw"
net_ifaces: "eth2"
```
> **Caution**: This is just an exemplary configuration and must be adapted to the individual use-case!
