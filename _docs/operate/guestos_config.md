---
title: GuestOS configuration
category: Operate
order: 3
---


# GuestOS configuration
- TOC
{:toc}

An operating system configuration is defined in the `<os-name>-<os-version>.conf` in the `/data/cml/operatingsystems/` folder. The configuration includes OS name and version, supported hardware type, description of mounted images, init process path and parameters, build date, and others. Descriptions of mounted images include their hashes, size, and file system type.

## GuestOS configuration management

Similar to container configuration also direct access to guestOS specific configuration files is not possible from core0 container.
Intended control is granted through the control interface.

The corresponding commands of the control tool are `ca_register`,
`list_guestos`, `push_guestos_config` and `remove_guestos`:

**ca_register** is used to install a new root certificate inside the CML.
Thus, it is possible to provide customer specific GuestOSes, signed by
a certificate from that CA.

**list_guestos** provides the configuration in protobuf-text format of
the already installed GuestOSes which have a valid signature.

**push_guestos_config**  is used to install new GuestOSes as well as
to update existing ones. The `cmld` checks if the config contains a valid
signature and matches the included image hashes, before accepting the new/updated GuestOS.

**remove_guestos**  is used to remove GuestOSes.


## GuestOS configuration specification
The full GuestOS configuration contains following fields:

```
// The following three fields together should UNIQUELY identify the actual guestos image files and config:
required string name  // unique name of the operating system
required string hardware // target hardware; must match hardware_get_name(), e.g. "i9505", etc.
required uint64 version // version string for the guest OS

repeated GuestOSMount mounts // list of mounts inside the container
optional string init_path [default = "/init"];  // path to the init binary, e.g. "/init"
repeated string init_param // parameters (argv) for init
repeated string init_env  // environment variables
repeated GuestOSMount mounts_setup // list of mounts for setup mode of a container

optional bool feature_install_guest [default = false]

optional uint32 min_ram_limit [default = 128] // required minimum RAM size (MBytes)
optional uint32 def_ram_limit [default = 1024]  // default RAM size (MBytes)

// Descriptive information (for GUI):
required I18NString description // description/full name
optional I18NString description_long // help text
optional string upstream_version // upstream version
optional bytes icon // name of icon file
optional string build_date // build date

optional string	update_base_url // provide url to file server which hosts the actual image data (overwrites device.conf)
```
The original Protobuf formatted file can be found [here](https://github.com/gyroidos/cml/blob/main/daemon/guestos.proto).


### Parameter mounts
The repeated ```mounts``` parameter list all mounts inside the container and is of type ```GuestOSMount``` which is specified as follows:

```
message GuestOSMount {
	// Path for the image files is derived from guestos_path/guestos_name.
	required string image_file = 1; // name of the image file, e.g. system
	required string mount_point = 2; // mountpoint inside the container
	required string fs_type = 3; // file system type, e.g. "ext4"

	enum Type {
		SHARED = 1; // image shared by all containers of same OS type
		DEVICE = 2; // image file is copied from a device partition
		DEVICE_RW = 3; // image file is copied from a device partition
		EMPTY = 4;  // empty, created when a corresponding container is first instantiated
		COPY = 5;   // deprecated
		FLASH = 6;	// image to be flashed to a partition (e.g. boot.img; base system updates only for now)
		OVERLAY_RO = 7; // read only overlay images e.g. for system features
		SHARED_RW = 8; // image shared by all containers of same OS type (writable tmpfs as overlay)
		OVERLAY_RW = 9; // similar to EMPTY image, however overlayed on given mount_point (writable persitent fs as overlay)
		BIND_FILE = 10;
		BIND_FILE_RW = 11;
	}
	required Type mount_type = 4;   // type of the image file

	// The following three fields are only used for EMPTY mount types:
	optional uint32 min_size = 6 [default = 10];	// required minimum size (MBytes) for EMPTY partition
	optional uint32 max_size = 7 [default = 16384]; // allowed maximum size (MBytes) for EMPTY partition
	optional uint32 def_size = 8 [default = 1024];  // default size (MBytes) for EMPTY partition

	// The following two fields are only used when an actual image file is provided:
	optional uint64 image_size = 10;     // size (bytes) of the image
	optional string image_sha1 = 11; // must NOT be used anymore
	optional string image_sha2_256 = 12;

	optional string mount_data = 13;  // mount_data used for mount syscall, e.g. "context=" for selinux
}
```
The ```image_sizes``` parameters of a [container configuration](/operate/container_config) must respect the minimal maximal sizes as defined in the respective GuestOS configuration.

### Parameter mounts_setup
The repeated ```mounts_setup``` parameter list all mounts inside a container for its setup mode.
See [basic operation documentation](/operate/control) for information on the different states of a container.

### Parameters init_param and init_env
```init_param```is used to provide parameters to init.
```init_env``` is used to set environment variables.
> Note that both are repeated strings. Therefore, every part of the overall string you want to pass on must be encompassed by its own ```init_param```/```init_env``` parameter!

## Example GuestOS configuration
The following example depicts a configuration for Debian as GuestOS:
```
name: "deb"
hardware: "x86"
version: 1
init_path: "/sbin/init"
mounts_setup {
	image_file: "root"
	mount_point: "/"
	fs_type: "squashfs"
	mount_type: SHARED_RW
}
mounts {
	image_file: "enc_root"
	mount_point: "/"
	fs_type: "ext4"
	mount_type: EMPTY
}
mounts {
	image_file: "tmpfs"
	mount_point: "/data/"
	fs_type: "tmpfs"
	mount_type: EMPTY
	def_size: 12
}
description {
	en: "gnu/debian userland (x86)"
}
```

