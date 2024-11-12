---
title: Remote attestation
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

The attestation tool cannot connect to the Container Management Layer (CML) when using a QEMU bridge.
Thus, we use a TAP network.

```
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

```
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

```
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

<details markdown="0">
<summary style="display: list-item">Example output of a successful attestation</summary>

<pre>
2024-11-12T17:12:19.272396+0100 [70499] &lt;INFO&gt;  sock.c+251: Trying to open socket to node (host) 172.23.0.1 on service (port) 9505
2024-11-12T17:12:19.272450+0100 [70499] &lt;INFO&gt;  sock.c+217: Trying to connect to IPv4 address: 172.23.0.1 (172.23.0.1)
2024-11-12T17:12:19.273444+0100 [70499] &lt;INFO&gt;  sock.c+235: Successfully connected to 172.23.0.1
2024-11-12T17:12:19.273481+0100 [70499] &lt;DEBUG&gt; attestation.c+378: Sending attestation request to TPM2D on 172.23.0.1:9505
2024-11-12T17:12:19.273614+0100 [70499] &lt;INFO&gt;  attestation.c+383: Send message with size 14
2024-11-12T17:12:19.273680+0100 [70499] &lt;DEBUG&gt; attestation.c+384: Request with Nonce[8] ef 27 1a 34 4d b1 da 91
2024-11-12T17:12:19.273713+0100 [70499] &lt;DEBUG&gt; attestation.c+394: Register Response handler on sockfd=4
2024-11-12T17:12:19.316377+0100 [70499] &lt;INFO&gt;  attestation.c+78: Response contains quote (Length 121)
2024-11-12T17:12:19.316429+0100 [70499] &lt;DEBUG&gt; attestation.c+79: Quote[121] ff 54 43 47 80 18 00 22 00 0b cf 23 cf 63 a0 cb 59 d3 52 7e 0d a1 4a 75 9d 1b 05 dd d6 d1 7d a8 05 27 46 73 01 31 7d e1 00 91 00 08 ef 27 1a 34 4d b1 da 91 00 00 00 00 00 36 9e f2 7d c8 4e 62 58 9c 2f b2 01 59 b6 fc 9d 1c 87 05 67 00 00 00 01 00 0b 03 ff 0f 00 00 20 e7 51 38 ab 44 6e ce b9 42 92 a7 c1 c3 ea a1 5a 88 f6 8d 8b 6f 44 3f a8 e6 d5 f7 58 c0 7e 9f f1
2024-11-12T17:12:19.316459+0100 [70499] &lt;DEBUG&gt; attestation.c+87: Response contains signature (Length 262)
2024-11-12T17:12:19.316503+0100 [70499] &lt;DEBUG&gt; attestation.c+88: Signature[262] 00 14 00 0b 01 00 88 79 bf c0 5c 2e 54 9f ad 3d 5c 39 7a a7 c0 f9 45 1a 2d 9a d0 43 42 ed a8 9b 8e c9 05 3f 34 78 59 8d 63 c5 5c 80 eb bc bc 84 2a 23 38 16 7e 55 69 73 f0 81 44 ff 1c 62 08 23 62 0e 35 f3 ad cd 0a ce e7 79 44 c6 2d 0d b2 1f 34 c3 1d 58 e6 17 de a8 81 8a f4 9a 8a 2c 24 a5 39 b5 11 9b be 0e ec f3 c7 97 18 ff e3 dd a3 b0 db 17 fd a3 0c e6 66 df 3a 89 aa 90 42 1e b0 d3 45 89 c5 c0 0d db 0f 98 4b 86 f0 5c 45 21 87 48 2e 26 e3 f0 95 c5 24 5a 48 9c fc bb 54 65 24 8c 74 86 09 7c aa c4 9c 06 66 31 54 cc 7d e2 1e 28 6c 5f 78 7f b2 97 15 5d d1 cf 0d db b1 52 ae 54 29 2e a3 d4 3a 30 11 f5 ad 6c d9 9c 3a db ad a6 58 0b df 85 dd 3b 57 ef 75 ac 0b 0f 10 20 ed d8 1e 83 b9 e6 2d ba 47 4a 5d ab 87 fa 5b 4c 3d fa c4 fe 4a 8a 0b b8 24 3f 98 e9 e4 30 66 1c a2 0d f7 26 6a 7c 32 86
2024-11-12T17:12:19.316532+0100 [70499] &lt;DEBUG&gt; attestation.c+99: Verifying Response...
2024-11-12T17:12:19.316571+0100 [70499] &lt;DEBUG&gt; attestation.c+100: Hash Algorithm: SHA256
2024-11-12T17:12:19.316631+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_0 VERIFICATION SUCCESSFUL[32] 2f 02 e9 ae e6 4b 7a 45 1c 25 74 fd bf bc 16 4e 74 14 6d 92 aa d5 84 21 73 e8 e5 01 79 cc 3f ff
2024-11-12T17:12:19.316682+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_1 VERIFICATION SUCCESSFUL[32] ed 00 d0 89 f6 07 aa 34 26 df 6e 2f 5b 42 59 b5 30 63 52 ed 93 e4 d9 24 df c6 2f a4 ab ac 07 f5
2024-11-12T17:12:19.316718+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_2 VERIFICATION SUCCESSFUL[32] 2b cd 47 c9 e0 dd 38 68 0e fc 33 07 69 13 af fd cf de 46 49 2b 23 e5 62 3b 2e a8 dc cd d9 02 0e
2024-11-12T17:12:19.316750+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_3 VERIFICATION SUCCESSFUL[32] 3d 45 8c fe 55 cc 03 ea 1f 44 3f 15 62 be ec 8d f5 1c 75 e1 4a 9f cf 9a 72 34 a1 3f 19 8e 79 69
2024-11-12T17:12:19.316782+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_4 VERIFICATION SUCCESSFUL[32] e4 3f b3 67 9d 46 dc 65 de ad 5c 8e 40 fd 92 59 e6 41 8b 4d 30 72 24 12 5d 8d a0 c7 b8 d4 c6 94
2024-11-12T17:12:19.316815+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_5 VERIFICATION SUCCESSFUL[32] db 06 01 db 51 3a e7 fc 76 70 50 b9 33 ac be f8 52 cb 2f 9f cd 45 22 80 a1 0e e4 80 94 de e9 0f
2024-11-12T17:12:19.316849+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_6 VERIFICATION SUCCESSFUL[32] 3d 45 8c fe 55 cc 03 ea 1f 44 3f 15 62 be ec 8d f5 1c 75 e1 4a 9f cf 9a 72 34 a1 3f 19 8e 79 69
2024-11-12T17:12:19.316890+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_7 VERIFICATION SUCCESSFUL[32] b5 71 0b f5 7d 25 62 3e 40 19 02 7d a1 16 82 1f a9 9f 5c 81 e9 e3 8b 87 67 1c c5 74 f9 28 14 39
2024-11-12T17:12:19.317065+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_8 VERIFICATION SUCCESSFUL[32] 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
2024-11-12T17:12:19.317114+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_9 VERIFICATION SUCCESSFUL[32] 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
2024-11-12T17:12:19.317160+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_10 VERIFICATION SUCCESSFUL[32] f5 96 04 d5 4e 85 c9 cb 2d f4 4f d7 cf 51 f8 c1 e1 82 49 9f 15 43 6f ec d8 9c cf 03 8f d9 cb 85
2024-11-12T17:12:19.317202+0100 [70499] &lt;DEBUG&gt; attestation.c+144: PCR_11 VERIFICATION SUCCESSFUL[32] 12 f3 b8 1e 9a 04 d0 40 dd 1d 3c dc 3c a3 c1 6a d5 e1 b3 fa 17 85 4e 4b ad 68 02 f9 6d 3e 3f 0e
2024-11-12T17:12:19.317284+0100 [70499] &lt;DEBUG&gt; attestation.c+165: Nonce sent[8] ef 27 1a 34 4d b1 da 91
2024-11-12T17:12:19.317318+0100 [70499] &lt;DEBUG&gt; attestation.c+166: Nonce rcvd[8] ef 27 1a 34 4d b1 da 91
2024-11-12T17:12:19.317352+0100 [70499] &lt;DEBUG&gt; attestation.c+172: Nonce VERIFICATION SUCCESSFUL
2024-11-12T17:12:19.319118+0100 [70499] &lt;DEBUG&gt; ssl_util.c+1708: Hash algo: SHA256
2024-11-12T17:12:19.319473+0100 [70499] &lt;DEBUG&gt; ssl_util.c+1053: Verifying signature with OpenSSL default padding scheme
2024-11-12T17:12:19.319513+0100 [70499] &lt;DEBUG&gt; ssl_util.c+1061: Signature successfully verified
2024-11-12T17:12:19.319580+0100 [70499] &lt;INFO&gt;  attestation.c+195: VERIFY QUOTE SIGNATURE SUCCESSFUL
2024-11-12T17:12:19.319630+0100 [70499] &lt;DEBUG&gt; attestation.c+199: Quote PCR Digest[32] e7 51 38 ab 44 6e ce b9 42 92 a7c1 c3 ea a1 5a 88 f6 8d 8b 6f 44 3f a8 e6 d5 f7 58 c0 7e 9f f1
2024-11-12T17:12:19.319679+0100 [70499] &lt;INFO&gt;  attestation.c+214: VERIFY AGGREGATED PCR SUCCESSFUL
2024-11-12T17:12:19.319714+0100 [70499] &lt;INFO&gt;  ima_verify.c+338: Verify IMA TPM PCR SUCCESSFUL
2024-11-12T17:12:19.319748+0100 [70499] &lt;INFO&gt;  container_verify.c+57: Verifying container /data/cml/operatingsystems/trustx-coreos-20241018121538/root.img
2024-11-12T17:12:19.319783+0100 [70499] &lt;INFO&gt;  container_verify.c+67: Verify container TPM PCR SUCCESSFUL
2024-11-12T17:12:19.319814+0100 [70499] &lt;WARN&gt;  container_verify.c+68: Verify container signatures not yet implemented
2024-11-12T17:12:19.319845+0100 [70499] &lt;DEBUG&gt; attestation.c+288: ---------------------------
2024-11-12T17:12:19.319876+0100 [70499] &lt;DEBUG&gt; attestation.c+289: REMOTE ATTESTATION: SUCCESSFUL
2024-11-12T17:12:19.319907+0100 [70499] &lt;DEBUG&gt; attestation.c+290: ---------------------------
2024-11-12T17:12:19.319940+0100 [70499] &lt;INFO&gt;  attestation.c+319: Handled response on connection 4
</pre>
</details>
