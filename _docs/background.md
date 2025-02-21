---
title: Background
category: General
order: 6
---

# Background

GyroidOS was formerly developed under the code name trust\|me, which stood for "trusted mobile equipment".
Initially developed for mobile devices, trust\|me sought to run multiple, systematically isolated Android instances on a
single device. Motivated by the 'bring your own device' problematic in enterprises, a prevalent use case was running a business
and private Android instance on a single smartphone. In contrast to other approaches, trust\|me used OS-level
virtualization capabilities of the Linux kernel, allowing to run the Android instances in _containers_ (using
namespaces and cgroups features). In order to systematically isolate these containers, trust\|me leveraged the
cgroups devices subsystem, Linux capabilities, SELinux and implemented an LSM stacking to enforce SELinux
policies both inside containers and globally.

With this approach, trust\|me not only achieved a reasonable level of security but also a great level of
performance, allowing seamless container switches and an almost native user experience. We established a usage
model where one container was in the foreground at a time, appearing at the display, while others were in the
background and could be toggled by a long power button press.

Following this approach, however, several technical challenges requiring intense development efforts arise
when using mobile devices with trust\|me in practice.
The first challenge is to determine the hardware devices a container may uses. For instance, the Wi-Fi, radio,
GPS or bluetooth peripherals. As soon as multiple containers may use hardware devices, access to them must be
virtualized. This can become a complex task. Some hardware device drivers may be implemented entirely in the
kernel (trust\|me leveraged the _device namespaces_ feature not part of a mainline Linux kernel), while other
devices may implement parts in user space (such as a wifi supplicant or the radio interface). For virtualizing
devices in user space, trust\|me implemented multiplexers in the core container.
Another challenge was that trust\|me required modifications to the Linux kernel and minor changes within the
Android OS. With frequent new versions of both kernel and Android OS, this leads to constantly lagging behind
when not investing high effort. Further, the short product lifecycles of smartphones and tablets meant a
constant effort in porting trust\|me with its hardware device virtualization components to the most recent ones of a
wide range of devices.

The latest supported device was the Nexus 5X running Android 7, for which we still provide
[build](/build/android) and [deploy](/deploy/smartphone) instructions. However, due to the high effort, we
decided to abandon the line of work with mobile devices. In the meantime, virtualization solutions like LXC
and Dockers gained more and more attraction on the market. For that reason, we decided to open source
trust\|me as an alternative to other
containerization solutions on the market. We target x86 and embedded Linux platforms running distributions
like Debian inside containers and neither requiring tedious OS modifications, massive hardware device
virtualization nor a container foreground-background model.

This makes GyroidOS more lean, easier to maintain and easier to apply on a wide range of x86 and ARM
platforms.
As GyroidOS was always developed as a security-centric solution, we designed a modular, privileged
virtualization layer. We moved all components that are critical yet not necessarily required as part of this layer to
a less privileged core container (e.g., update and remote management functionalities).
Further, we target not only the separation of critical user space execution contexts, but also platform
security. As a result, our code base supports features like full disk encryption, secure and measured boot with remote attestation
using a TPM. We integrate a customizable PKI into GyroidOS builds that allows not only kernel and module
signing, but also signing the virtualization layer and all containers.
We are also developing functionality for two-factor authentication to bind containers and their data
encryption to Secure Elements, and for leveraging TEEs for storing cryptographic keys and executing ciphers
within hardware-isolated boundaries.

A detailed introduction to the core concepts of OS-Level virtualization
and the separation of privileged instances in GyroidOS is provided in [this slideset](https://github.com/gyroidos/gyroidos/raw/master/doc/trustme.pdf).
The document is centered around the legacy Android-based version of trust\|me. However, the
core concepts apply likewise to the current version.
