---
title: Hosted Mode
category: Deploy
order: 5
---
# Hosted mode
- TOC
{:toc}

GyroidOS containers can also be run natively on your host, using the hosted mode.
This section describes how to run the hosted mode.
These instructions have been tested and work on Debian 10 stable. 

## Requirements
Have a prebuilt container image ready or build one yourself as described in [Build](/build/build).

### Required packages
Install all required packages with the following command: 
```
apt-get install git build-essential unzip re2c pkg-config check \
    lxcfs libprotobuf-c-dev automake libtool libselinux1-dev \
    libcap-dev protobuf-c-compiler libssl-dev udhcpd udhcpd
```
### Protobuf-c-text
To install protobuf-c-text, run the following commands:
```
git clone https://github.com/gyrdoidos/external_protobuf-c-text
cd external_protobuf-c-text/
./autogen.sh
./configure --enable-static=yes
make 
make install
ldconfig
```

## Installation
Clone, compile and install the neccesary components with
```
git clone https://github.com/gyroidos/cml
make -f Makefile_lsb 
sudo make -f Makefile_lsb install
```


## Setup
1. Run scd once to initialize /var/lib/cml/tokens 
3. You can either push your own certificate by using cml-control push_ca or copy the ssig_rootca.cert from your build to /var/lib/cml/tokens
4. Run scd again, this time it will start a loop and keep running
5. Run cmld and keep it running
2. Install your guestos as described in [GuestOS configuration](/operate/guestos_config)
6. You can now use control as described in [Basic Operation](/operate/control)

