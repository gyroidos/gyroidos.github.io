---
title: Basic operation
category: Operate
order: 1
---


# Containers and GuestOSes

- TOC
{:toc}
## Containers and guest operating systems

Each container has a corresponding configuration file defining its key features.
Every container runs a certain operating system, which also has to be defined in a configuration file.
Note that several containers may run the same operating system.

Both container and OS configuration file formats are composed of several ```key: value``` lines.
A detailed description of the container configuration can be found [here](/operate/container_config); the guestOS configuration is described [here](/operate/guestos_config).

## Basic GyroidOS operation

GyroidOS is operated using a socket-based interface. This interface is used by the *control*
command-line tool, which is installed together with GyroidOS. It is available from the
privileged container (core0) and the debugging shell of CML.
This tool is just for basic usage and demonstration of the control interface.
For productive use cases an implementation of the protobuf-based control interface should be
used, for instance in a web-based UI.

The *control* tool allows administration and configuration of the GyroidOS platform, such as creating and starting containers, running a given command inside a container, etc.
The available actions are listed below.

Usually, container specific commands use the container-uuid as parameter to identify the
corresponding container. However, for convenience also the container name could be used.
However, if you have several containers with the same name, always the first matching
one is used. In that case, you have to specify the UUID to address all containers.

* Change the PIN/Passphrase for the container's token (USB or Softtoken)
```
control change_pin <container-uuid>
```
This command provides an interactive prompt for the old and new
Pin/Passphrase for the container's token. Remember, the token is used for
wrapping the container encryption keys and the here set PIN/Passphrase
must be provided at container start and stop.
(default passphrase for inital container provisioning is `trustme`)

* Start container:
```
control start <container-uuid> [ --setup ]
```
This command starts the container with the given UUID. In order to do so, the container has to be created beforehand by 'control create'.
The optional `--setup` parameter allows you to manipulate
the containers root file system tree including all encrypted overlays mounted at `/setup`.
This could be used to bootstrap an encrypted container, see [example: Using GuestOs debos](/operate/examples/#example-using-guestos-debos).
When entering this command, you will be interactively asked for the Passphrase/PIN of the token
used for container en/decryption. If the container configuration specifies that an external USB pin
reader device should be used (see [Container Configuration](/operate/container_config)), the
PIN/passphrase must be entered via this device instead of the standard input keyboard.

* Stop container:
```
control stop <container-uuid>
```
This command stops the currently running container with the given UUID.
When entering this command, you will be interactively asked for the Passphrase/PIN of the token
used for container en/decryption. If the container configuration specifies that an external USB pin
reader device should be used (see [Container Configuration](/operate/container_config)), the
PIN/passphrase must be entered via this device instead of the standard input keyboard.

* Create container configuration from the given template config file:
```
control create <config-template-file> [<container.sig> <container.cert>]
```
This generates a new container configuration with a random UUID from a configuration file and optionally
a signature and a certificate file.
The configuration template file has to be given using protobuf-text syntax. It must contain at least the following:
```
name: "<container name>"
guest_os: "<guest os name>"
color: <color for UI as argb e.g. 0xff00ffff>
```
You can use `control list_guestos` to get the name for available GuestOSes.

* Remove container:
```
control remove <container-uuid>
```
Deletes the given container completely including configuration, data images and corresponding wrapped keys.

* Wipe container:
```
control wipe <container-uuid>
```
Wipes the specified container.

* Wipe Device:
```
control wipe_device
```
Wipes all containers on the device.

* Container current state:
```
control state <container-uuid>
```
This returns the current state of the given container. Possible states are:
	- `STOPPED`: The container has either not been run, was explicitly stopped or the init process of the container exited
	- `STARTING`: The container was started using 'control start' and the container manager is preparing to launch the container.
	- `BOOTING`: The container manager finished preparing the container and the control was handed over to the container's init process
	- `RUNNING`: The container was initialized successfully and is now running.
	- `FREEZING`: The container is in the process of freering after a 'control freeze' was issued
	- `FROZEN`: The container is frozen after a 'control freeze' was issued
	- `ZOMBIE`: The container is a zombie
	- `SHUTTING_DOWN`: The container is in the process of shutting down
	- `SETUP`: The container was initialized successfully and is now running in setup mode (target rootfs mounted at /setup)
	- `REBOOTING`: The container is rebooting

* List all available containers and their state:
```
control list
```

* Container config:
```
control config <container-uuid>
```
Prints the container config to stdout. This could be used for editing the current config.

* Update a container configuration file
```
control update_config <container-uuid> <container.conf> [<container.sig> <container.cert>]
```
Sends a new config file `container.conf` and optionally a signature and certificate file to the
`cmld`. It is not applied to running containers directly. You have to stop the container and
trigger a reload.

* Reload container configuration
```
control reload
```
This command reloads all container configs of all containers in state `STOPPED`
into the running `cmld`.

* Run command inside the specified container:
```
control run <container-uuid> <command> [<arg_1> ... <arg_n>]
```
**Experimental**, some characters especially control characters may not work as expected.
The given command is executed in the context of the given container. Before executing the command, the process is made session leader and get's a new PTY attached.

* Assign a network interface to the container with the specified UUID:
```
control assign_iface --iface <interface-name> <container-uuid> [--persistent]
```
The 'persistent' option also applies the change to the container's config file, such that the assignment persists container reboot

* Un-assign a network interface to the container with the specified UUID:
```
control unassign_iface --iface <interface-name> <container-uuid> [--persistent]
```
The 'persistent' option also applies the change to the container's config file, such that the assignment persists container reboot.

* List all network interfaces currently assigned to the container with the specified UUID:
```
control ifaces <container-uuid>
```
* Freeze container:
```
control freeze <container-uuid>
```
Freezes the specified container, i.e. stops the processes of the container from being scheduled.\
**Experimental**: Processes might behave unexpectedly if the container is frozen for a longer time period

* Unfreeze container:
```
control unfreeze <container-uuid>
```
Unfreezes the specified container that was previously frozen with `control freeze`

* List GuestOS configuration:
```
control list_guestos
```
Lists the configuration of all installed GuestOSes.

* Register a new CA for GuestOS signature verification
```
control ca_register <ca.cert>
```
This command registers a new certificate in trusted CA store for allowed GuestOS signatures.

* Install new GuestOS or update GuestOS
```
control push_guestos_config <guestos.conf> <guestos.sig> <guestos.pem>
```
This command can be used to push the specified GuestOS config, signature, and certificate files
of a corresponding GuestOS. This would trigger a download of the corresponding GuestOS image
files from either the download URL provided in the `guestos.conf` or the default
download url in the CML's `device.conf`. If an older version is already installed an
update would be triggered after a reboot of the whole system.

* Remove/Delete a GuestOS
```
control remove_guestos <guestos name>
```
Deletes the GuestOS by the given `guestos name`. All associated files such as
configuration, signature and shared images files are removed permanently.
If the GuestOS is still in use by any container, this command will do nothing.
In this case you have to delete all remaining containers using the GuestOS
with `control remove`, see above.

* Get Certificate request of Device
```
control pull_csr <device.csr>
```
During provisioning mode it is posible to
sign a device private key with a customer CA. This command pulls
the corresponding csr from the virtualization layer and
stores the csr in the provided file name `<device.csr>`.

* Store the signed device certificate
```
control push_cert <device.cert>
```
This command pushes back a device certificate provided in file `<device.cert>`.
Remember, you have to provide your own mechanism to transfer and sign
the certification request to your CA. Further, you have to store the
corresponding Customer CA root certificate in the trusted CA store, see `control ca_register`.

* Get device stats
```
control device_stats
```
Gives information about the system's disk usage and overall memory use/availabiltity
which is available in the CML.

* Reboot device
```
control reboot
```
Reboots the device, shutting down any containers which are running

* Set the device to the provisioned mode
```
control set_provisioned
```
Set the device to the provisioned mode after initial configuration. This setting is persistant.
As soon as this command is run, the device is provisioned and only allows a subset of commands to be
run. All other ```control``` commands will return CMD_UNSUPPORTED error code.\
The set of allowed commands in provisioned mode is:
```
control state
control list
control change_pin
control create
control start
control stop
control update_config
control ifaces
control list_guestos
control push_guestos_config
control reboot
control device_stats
```

* Get the device status regarding provisioned mode
```
control get_provisioned
```
Gives information about the provisoned state, true or false.
