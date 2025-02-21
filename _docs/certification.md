---
title: Certification
category: General
order: 5
---

# Certification
- TOC
{:toc}

GyroidOS can be used to support different certification processes.
Some of the provided security features should allow to be used as TSF for Common Criteria certification
with GyroidOS as part of the Target of Evaluation (TOE).
As part of the trusted connector GyroidOS already got the IDS-ready label (Trust Profile) after having its implementation concept evaluated.

Remember that we only describe the features which are supported by the mainline implementation of GyroidOS
(consisting of the container management layer daemon _cmld_, the smartcard and security helper daemon _scd_, the trusted platform module 2 helper daemon _tmp2d_)
and the provided yocto based CML distribution, companioned by its reference c0 implementation gyroidos-coreos.

In a nutshell planned certifications are:

- Support for Common Criteria certification
- DIN SPEC 27070 - IDS Trust Security profile (ready label as part of the Trusted Connector already received)
- Support for IEC-62433 certification

## Security Functionality to support Common Criteria Evaluations

The following briefly described security functionality can support Common Criteria Evaluations
where the CML including its components cmld, tpm2d, scd as part of the Target of Evaluation (TOE) provides a secure isolation service for containers.

|TSF Description | Implementation / Components | State |
|--------------------|----------|--|
**CML Audit.** 	 Enables monitoring key events that occur in the components of the CML. It provides mechanisms to store and forward audit events occurring in the TOE (cmld itself) and it’s operational environment (OE) namely the Linux kernel. | cmld as auditd, kernel audit | done |
**CML Secure Container Init.** Ensures code integrity and authenticity for containers and their GuestOSes instantiated by the cmld. | UEFI secure boot, kernel module signing, IMA appraise for Linux firmware as trusteded computing base (TCB) for the CML; cmld and scd for containers | done |
**CML Container Isolation.** Ensures that no uncontrolled information exchange between containers is possible. Only a write-up according to the Bell-La Padula security model from c0 compartment to service containers is allowed. | cmld configures Linux namespaces, cgroups and capabilities | done |
**CML Container Data Storage.** Ensures data integrity, authenticity and confidentiality for service containers by utilizing a Secure Element as secure key storage. | cmld and scd using libctccid for SmartCardHSM integration, dm-crypt and dm-integrity | done |
**CML System Data Storage.** Ensures data confidentiality for CML data partition based on TPM as secure key storage | tpm2d and ibmtss for kernel dm-crypt | done |
**CML Device Access Control.** Ensure that only configured device access is allowed for a container. If exclusive access is configured, this is to be enforced by this TSF. | cmld configures device cgroups and network devices access (netns) | done |
**CML Updates.** Ensures that only authentic and integrity protected updates are performed, either to the security supporting parts of the OE – kernel, modules and firmware – as well as the TOE – the CML – and the compartment images and configuration. | cmld, scd | done |


## DIN SPEC 27070 - IDS-Specific Requirements
Relevant IDS-specific requirements specified in the DIN SPEC 27070 \[[DE](https://www.beuth.de/de/technische-regel/din-spec-27070/319111044)\]
\[[EN](https://internationaldataspaces.org/din-spec-27070/)\] which are fulfilled or supported by the mainline GyroidOS software stack.
Since the IDS Component Certification Catalogue is slightly advanced to the standardized DIN SPEC, we refer to version 2.1.0 of the Component Certification Catalogue.

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
|COM 01 - Protected connection			| c0 gains all physical network interfaces and thus can enforce VPN/IDSCPv2 connections by firewall means | done |
|COM 02 - Mutual authentication			| Device certificate with TPM-protected private key as client certificate (scd, ibmtss) | done |
|COM 03 - State of the art cryptography		| kernel, scd (Openssl), and tpm2d use crypto in compliance with BSI TR-02102-1 | done |
|COM 04 - Remote attestation			| UEFI measured boot, kernel (IMA) for modules and firmware measurements, cmld for container image measurements, tpm2d for server side, rattestation tool for client side | partially done |
|COM 05 - Platform integrity			| UEFI secure boot, kernel and all CML components as EFI binary, kernel module signing facility, IMA appraise for firmware | done |
|COM 06 - Configuration and app integrity	| Signed container images and configuration files provided by cmld, scd | done |  
|IAM 01 - Connector identifier			| Device certificate with TPM-protected key (tpm2d, ibmtss) | done |
|IAM 02 - Time Service				| Container with ntpd, privileged access to system time (CAP\_SYS\_TIME in host System) | partially done |
|IAM 03 - Online certificate status check	| Integration of stunnel or IDSCPv2 with OCSP in certificate possible | planned |
| OS 01 - Container support			| cmld configures Linux namespaces, cgroups and capabilities to span containers | done |
| OS 02 - App separation			| Service containers for apps, c0 for routing and management | done |
| OS 03 - Service authenticity and integrity	| Based on code signatures for the allowed containers, the authenticity and integrity of all containers are verified prior to installation and execution. cml provides mechanism to register trusted CA certificates. | done |
| OS 04 - System component authenticity and integrity | The authenticity and integrity of all (non-container) system components (kernel, cmld) are verified as part of Secure Boot. | done |
| OS 05 - Container separation			| The CML is protected from the applications in the containers by Linux kernel security mechanisms (capabilities, cgroups, namespaces) | done |
| OS 06 - Backup encryption			| The cmld encrypts and signs all data partitions and sends them to a remote backup server | planned |
| APS 01 - App signature			| Container Images are signed and the cmld verifies those signatures before starting the container | done |
| APS 02 - App signature verification		| cmld verifies the signatures for all container images before installation (after download) and before each execution of the container. | done |
| APS 04 - Requirements for the runtime environment  | RAM and CPU resources in container config, cmld sets kernel cgroups accordingly | done |
| APS 05 - App installation			| Apps are independent GyroidOS containers. | done |

## IDS / IEC 62443 Requirements
Relevant IDS requirements (DIN SPEC 27070 / IDS Component Certification Catalog Version 2.1.0) which are also part of the IEC 62443-4-2.
The CR in the IDS world are equivalent to the IEC 62443-4-2 and derived from the IEC 62443-3-3 SR.

### 62443-IAC: Identification and Authentication Control 

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
| CR 1.1 – Human user identification and authentication | (c0) Human users only interact with the connector via SSH, or locally via c0. Linux user management in c0, password and ssh-keys during provisioning | done |
| CR 1.1 (1) – Unique identification and authentication | (c0) ssh-key and PAM password for local logins | done |
| CR 1.1 (2) - Multifactor authentication for all interfaces | (c0) deny local logins and enforce password for ssh keys, (optional) SE with User PIN for containers | done |
| CR 1.2 – Software process and device identification and authentication | Device certificate with TPM-protected private key for identification | done |
| CR 1.2 (1) - Unique identification and authentication | The CA that issues the certificate ensures that the certified public keys are unique, cmld provides a CSR for the device certificate | done |
| CR 1.3 – Account management  | Linux user management in c0 | done |
| CR 1.4 – Identifier management  | Device certificate with device UUID | done |
| CR 1.5 – Authenticator management | ssh-keys and user-pin combined with system pin of cmld for managing containers | done |
| CR 1.5 (1) - Hardware security for authenticators | Device certificate with TPM-protected private key for identification | planned |
| CR 1.7 – Strength of password-based authentication | (c0) only ssh public-key access, local user access PAM or disable completely | done |
| CR 1.8 – Public key infrastructure certificates | Device certificate as part of PKI | done |
| CR 1.9 – Strength of public key-based authentication | Device certificate validation in rattestation client | done |
| CR 1.9 (1) - Hardware security for public key-based authentication | TPM private key for Device certificate | done |
| CR 1.10 – Authenticator feedback  | A login attempt using SSH with an invalid or not stored private key or the usage of a user PIN is denied with a standard error message which does not provide any insight. | done |
| CR 1.11 – Unsuccessful login attempts | (c0) PAM tally2 for local and remote logins | planned |

### 62443-UC: Use Control

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
| CR 2.1 - Authorization enforcement | (c0) Linux user management, SSH login | done |
| CR 2.1 (1) – Authorization enforcement for all users (humans, software processes and devices) | (c0) Linux user management | done |
| CR 2.1 (2) - Permission mapping to roles| (c0) Linux user management, SSH login | done |
| CR 2.5 – Session lock | (c0) The SSH server terminates all remote sessions after a configured time of inactivity as described in CR 2.6. | done |
| CR 2.6 – Remote session termination| (c0) The SSH server supports a timeout, the admin can kill any existing SSH session and the user can disconnect actively. | done |
| CR 2.8 – Auditable events | See TSF Audit, provided by cmld and kernel audit| done |
| CR 2.9 – Audit storage capacity | cmld's device config provides option for storage capacity | done |
| CR 2.9 (1) - Warn when audit record storage capacity threshold reached | cmld generates an audit record | done |
| CR 2.11 – Timestamps | cmld uses local synchronized system time for audit records | done |
| CR 2.11 (1) – Time synchronization | ntpd in container | planned |
| CR 2.11 (2) – Protection of time source integrity | NTPsec in ntp container | planned |
| CR 2.12 – Non-repudiation | (c0) pid and uid during login attempt, PAM audit log, kernel audit framework | done |
| CR 2.12 (1) – Non-repudiation for all users | c0 and all service containers use PAM module for kernel audit framework | planned |

### 62443-SI: System Integrity

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
| CR 3.4 – Software and information integrity | Secure boot UEFI kernel and CML, Linux IMA appraise for firmware, cmld and tpm2d for GuestOS signatures | done | 
| CR 3.4 (1) – Authenticity of software and information |  Measured boot of all stages (UEFI, IMA, cmld and tpm2d) protected by TPM and rattestation for verification | done |
| CR 3.4 (1) – Authenticity of software and information |  Measured boot with DRTM (Intel-TXT, tboot) | planned |
| CR 3.4 (2) – Automated notification of integrity violations | Recovery system for audit log | planned |
| CR 3.8 – Session integrity | (c0) ssh server | done |
| CR 3.9 – Protection of audit information  | use signed audit records with device key protected by TPM | planned |

### 62443-DC: Data Confidentiality

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
|CR 4.1 - Information confidentiality | data at rest protection see *TSF CML Container Data Storage* and *TSF CML System Data Storage* | done |
|CR 4.2 - Information persistence | Reset TPM FDE key for whole system (tpm2d), delete wrapped container keys (cmld) | done |
|CR 4.2 (1) - Erase of shared memory resources | Linux kernel memory subsystem | done |
|CR 4.2 (2) - Erase verification | cmld responds to container wipe | done |
|CR 4.3 - Use of cryptography  | BSI TR-02102-1 compliant crypto | done |

### 62443-RDF: Restricted Data Flow

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
| CR 5.1 – Network segmentation | Linux network namespaces, c0 as router | done |

### 62443-TRE: Timely Response to Events

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
CR 6.1 – Audit log accessibility | access to audit log through cmld in c0 | done |
CR 6.2 – Continuous monitoring | audit log forwarder to backend | planned |


### 62443-RA: Resource Availability

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
| CR 7.1 – Denial of service protection | Linux cgroups for CPU and RAM usage | done |
| CR 7.2 – Resource management | cmld to configure CPU and RAM limits | done |
| CR 7.3 – Control system backup | cmld to backup its configuration and logs | planned |
| CR 7.3 (1) - Backup integrity verification | Device private key signature on backup file | planned |
| CR 7.4 – Control system recovery and reconstitution | Use backup of CR 7.3 | planned |
| CR 7.6 – Network and security configuration settings | (c0) container backup | planned |
| CR 7.6 (1) – Machine-readable reporting of current security settings | cmld provides container and GuestOS configuration as protobuf, iptables/nftables tool in (c0) | done |
| CR 7.7 – Least functionality| only necessary device and network interfaces are allowed per default for containers |  done |

### 62443-NDR: Network Device Requirements

|Criteria/Requirement|Implementation and components | State |
|--|--------------------|----------|
| NDR 1.13 - Access via untrusted networks | nftables/iptabels in c0 | done |
| NDR 2.4 – Mobile code | Mobile code in form of service containers | done |
| NDR 2.4 (1) - Mobile code authenticity check | container integrity and authenticity through cmld | done |
| NDR 3.2 – Malicious code protection | only signed and validated containers are executed by cmld | done |
| NDR 3.10 – Support for updates | cmld provides mechanism to update CML, kernel and GuestOSes as well as container configuration | done |
| NDR 3.10 (1) – Update authenticity and integrity | only signed and validated updates for containers and CML are performed by cmld (see *TSF CML Updates*) | done |
| NDR 3.12 – Provisioning product supplier roots of trust | TPM and UEFI keys need to be provisioned in life cycle | done |
| NDR 3.13 – Provisioning asset owner roots of trust | cmld provides trusted CA store for additional owner CAs | done |
| NDR 3.14 – Integrity of the boot process | UEFI Secure Boot | done |
| NDR 5.2 – Zone boundary protection | network namespaces for service containers | done |
| NDR 5.2 (1) Deny all, permit by exception | nftables/iptables in c0 and service containers | done |
| NDR 5.2 (2) Island mode | nftables/iptables | done |
| NDR 5.2 (3) Fail close | nftables/iptables | done |
