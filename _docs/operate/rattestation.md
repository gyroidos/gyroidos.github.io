---
title: Remote attestation (rattestation)
category: Operate
order: 7
---

- TOC
{:toc}

# Remote Attestation (rattestation)
{:.no_toc}

Remote attestation validates the runtime integrity of a system by comparing the system's measured values against a predefined baseline.
The system's TPM cryptographically signs these measurements to guarantee their validity.

In the following, we detail how to attest GyroidOS running in a QEMU VM.

## Network Configuration

The attestation tool cannot connect to the Container Management Layer (CML) when using a QEMU bride.
Thus, we use a TAP network.

```bash
# Create a new tap
$ ip tuntap add dev "gyroidOS_tap" mode tap
# Start it
$ ip link set "gyroidOS_tap" up
# Assign an IP range
$ ip addr add 10.42.42.1/24 dev "gyroidOS_tap"
# Add route to C0
$ ip route add 172.23.0.0/24 dev "gyroidOS_tap"
# Add route to CML through C0
$ ip route add 172.23.0.1 via 172.23.0.2
```

## Software TPM Setup

As previously mentioned, the attestation requires a TMP module, which we will emulate using a software TMP.
Detailed instructions are available [in the deploy/qemu section](../deploy/qemu#use-tpm-emulation).

## QEMU

Install the required packages and create a container following [the QEMU setup instructions](../deploy/qemu).
Afterward, start QEMU with the following command.

```bash
qemu-system-x86_64 \
    --enable-kvm -m 4096 \
    -bios /usr/share/ovmf/OVMF.fd \
    -serial mon:stdio \
    -device virtio-rng-pci \
    -device virtio-scsi-pci,id=scsi \
    -device scsi-hd,drive=hd0 -drive if=none,id=hd0,file=/path/to/gyroidOS.img,format=raw \
    -device scsi-hd,drive=hd1 -drive if=none,id=hd1,file=containers.btrfs,format=raw \
    -netdev tap,id=net0,ifname="gyroidOS_tap",script=no,downscript=no \
    -device e1000,netdev=net0 \
    -chardev socket,id=chrtpm,path=/tmp/swtpmqemu/swtpm-sock \
    -tpmdev emulator,id=tpm0,chardev=chrtpm \
    -device tpm-tis,tpmdev=tpm0 \
    -vga virtio
```

## GyroidOS Network Configuration

The following commands must be run in the C0 container since all traffic is routed through C0 to the CML, which will complete the attestation request.
Access the CML terminal in the QEMU window, not the terminal used to launch QEMU.
Log in with the username `root`, no password is required.
Confirm that you are in the correct terminal by running `hostname`, which should return `trustx-core`.

```bash
# Since we don't use a DHCP server on the TAP, we have to manually assign an IP address
ip addr add 172.23.0.55/24 dev cmleth0
# Add route to TAP in case that it wasn't automatically created
ip route add 10.42.42.1/32 dev cmleth0
```


## Host Attestation Setup

The following commands are run on the host, not the QEMU VM.

1. Clone the [cml repository](https://github.com/gyroidos/cml/)
2. Navigate to the `cml/rattestation` directory.
3. Install the dependencies listed [in the README](https://github.com/glad-dev/cml/tree/kirkstone/rattestation#readme).
4. Create the log directory with `mkdir /data/logs` or change `#define LOGFILE_DIR "/data/logs"` in `main.c`.
5. Build the attestation tool with `make`.
6. Extract the first certificate from the trust chain located at `ws-yocto/out-yocto/test_certificates/ssig_subca.cert` and save it as `yocto.pem`.
7. Update the expected values for the PCRs in `rattestation.conf` if they are available.
8. Run the attestation tool with `./rattestation 172.23.0.1`.
