---
title: Smartphones (depct'd)
category: Build
order: 5
---

# Android Build for Smartphones (deprecated)
- TOC
{:toc}

> **Note**: We do not support the Android based smartphone build anymore.
However, for reference, we provide the build instructions -- which should still work -- here.
Supported devices are:
* Google Nexus 5 (hammerhead) (Android 7.1.2, 5.1.2)
* Nexus 5X (bullhead) (Android 7.1.2)

## Prepare your build machine
In the following, we briefly exemplify the setup of debian 8 (jessie).
For ubuntu have a look at [AOSP Initialize Build Environment](https://source.android.com/source/initializing.html)

### Install standard packages
For debian 8 (stable) this would be:

    apt-get install build-essential libc6-dev git-core gnupg flex bison gperf libsdl1.2-dev \
        libesd0-dev libwxgtk3.0-dev squashfs-tools zip curl libncurses5-dev zlib1g-dev \
        pngcrush schedtool libxml2 libxml2-utils xsltproc g++-multilib lib32z1-dev \
        lib32ncurses5-dev lib32readline-gplv2-dev gcc-multilib ccache abootimg \
        qemu-user-static parted qemu-user texlive-latex-base re2c python-protobuf \
        protobuf-compiler protobuf-c-compiler bc lzip
        
If you followed the AOSP instructions at 
[AOSP Initialize Build Environment](https://source.android.com/source/initializing.html), you need to install the
following addtional packages for trust|me

    apt-get install qemu-user-static parted qemu-user texlive-latex-base re2c python-protobuf \
        protobuf-compiler protobuf-c-compiler bc lzip

### Install java
For Java 8 add the jessie-backports to apt in `/etc/apt/sources.list`:
    
    # used for openjdk-8  
    deb http://ftp.debian.org/debian jessie-backports main

Install the JDK

    apt-get update
    apt-get install -t jessie-backports openjdk-8-jdk-headless openjdk-8-jre-headless

### Install "repo" tool
For more information on repo see [AOSP Download Source](https://source.android.com/source/downloading.html)

    mkdir ~/bin
    cd ~/bin
    wget https://storage.googleapis.com/git-repo-downloads/repo
    chmod a+x repo
    export PATH=$PATH:~/bin
    
### Install fastboot
    apt-get install android-tools-fastboot

### Configure "git"
    git config --global user.email "you@example.com"
    git config --global user.name "Your Name"
    
    
## Checkout and prepare build of trust|me
The trust|me branches are named after the corresponding aosp tags on which they are based. Currently
there are two branches for Android version 5.1.1 and 7.1.2:
*trustme-7.1.2_r33-github* and *trustme-5.1.1_r38-github*

    mkdir -p workspace
    cd workspace
    repo init -u https://github.com/trustm3/trustme_main -m trustme-hammerhead.xml \
        -b trustme-7.1.2_r33-github
    repo sync
    
### Prepare PKI
To later be able to sign your build (also replace the test keys inside android with release keys)
a test PKI will be setup during first build. This will include a user token which can be used for
container encryption.  
**Change the default passwords** in:

    trustme/build/device_provisioning/test_certificates/test_passwd_env.bash
    
The generated user token is not used by default as the device generates its own token during first boot.
However there are provisioning scripts which will replace the usertoken or you can replace it manually
after deployment as described in [Change default usertoken password](/deploy/smartphone#change-default-usertoken-password).

### Enable GApps as feature
If you want to be able to use gapps inside of your containers,
you have to download the corresponding gapps package to your workspace.
See [gapps for 7.1.2](https://github.com/trustm3/trustme_build/tree/trustme-7.1.2_r38-github/gapps)

### Build it
Just run
    
    make
    # or for signed release builds
    make dist-all dist-sign
    
