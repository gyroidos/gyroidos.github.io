---
title: Rollout
---


# Roll-out and Provisioning
{:.no_toc}

For secure roll-out and provisioning, several steps in a secure environment are required.

## Set secure boot keys

Before deploying the base system, set the trust anchors of the software signing PKI, e.g., in UEFI variables.
Set other required keys, e.g., the KEK and PK. See [Secure Boot Configuration](../deploy/x86.md#secure-boot-configuration)
> **Note:** If you use release images from Github add the following public key to your efi db\\
> [ssig_subca.esl](https://github.com/gyroidos/gyroidos/releases/download/v0.1/ssig_subca.esl)
(sha256: b52d9451de399ac5ce8d443ff0e118295b2ad9f08d781e53bc8d662c83ac341)

## Boot into provisioning mode

At the first boot, GyroidOS automatically boots into a provisioning mode.
In this mode, the virtualization layer exposes additional functionality to the core container via the control
interface.
At that time, the deployed GyroidOS base system is equipped with the software signing trust anchor and is
thus capable of starting the core container. In order to allow running other GuestOSes, you can add the GuestOS signing trust
anchors to the certificate store in the virtualization layer (via the control interface). This allows the
virtualization layer to verify any GuestOS that can be added to the system via the core container at any
time.

Further, the virtualization layer initializes the TPM and creates a device CSR corresponding to a TPM-bound
signing keypair. The core container can request the CSR from the virtualization layer.
This allows to sign the device CSR using the Device Sub CA and to deploy the device certificate back to the
target. During this step, the trust anchor for device certificates can be also be deployed in order to verify
other device certificates, such as a backend, which may have a device identity in the same PKI hierarchy.

Lastly, the virtualization layer creates a softtoken for wrapping container encryption keys.
This token can be replaced during provisioning with an own token, its password can be changed,
or the token can be removed to use a Secure Element in future builds.  

### Complete provisioning

Reboot the system to complete the provisioning. During the next boot, the GyroidOS base system no longer
boots into provisioning mode and can use the deployed certificates and tokens during operation.
This means that the control interface available in the core container no longer exposes the provisioning
functionality.
Future builds will come up with functionality to replace relevant key material during the operation to
complete the device lifecycle management.

## Self-Provisioning
Current development builds contain a self-provisioning mechansim.
The self provisioning first generates self-signed device certificates for testing.
The pre-deployed software signing trust anchors is used on development builds to verify all containers, i.e.
core containers and other deployed containers.

Further, an initial softtoken with password `trustme` is generated.
The token is used to wrap the encryption keys for container data and emulates a Secure
Element (or other tamper-resistant key store).
In future builds, GyroidOS will allow storing these  keys in Secure Elements.
At every container start, the softtoken's password must be provided via the core
container to the virtualization layer, which unlocks the softtoken or Secure Element, respectively.

### Complete self-provisioning
Just reboot the system after finishing initial provisioning with shell

    reboot

## Change the softtoken password
There are two options to change the passphrase of the softtoken.

### 1. Control Interface
You can just use the control tool to change the token's passhprase
at any time, either during provisioning or later on during normal operation by:
```
control change_pin
```

### 2. Openssl tool
You can change the password in the virtualization layer by running `openssl` during
provisioning mode or at the debug shell in development builds.
```
# unwrap existing token
openssl pkcs12 -in /data/cml/tokens/testuser.p12 -out /tmp/mycert.pem -nodes
# rewrap existing token, set new password
openssl pkcs12 -export -out /data/cml/tokens/testuser.p12 -in tmp/mycert.pem
# remove temp file
rm /tmp/mycert.pem
```
