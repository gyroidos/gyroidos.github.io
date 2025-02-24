---
title: Smartphones (depct'd)
category: Deploy
order: 6
---


# Deploy on Android Smartphones (deprecated)
- TOC
{:toc}
> **Note**: We do not support the Android based smartphone build anymore.

The deployment requires setting up the adbkey produced during build
which is used to flash the build artifacts with fastboot.

### adb key for deployment of containers
The trust|me adb access to the root namespace (ramdisk) is only allowed to one host adbkey.
This adb key is automatically generated during first build in
/trustme/build/device_provisioning/test_certificates/dev.user.adbkey[.pub]
You have to copy this key to your local adb configuration to be able to deploy containers later on.
    
Before you overwrite your adbkey make a backup:

    cp ~/.android/adbkey ~/.android/adbkey.bak
    
Then copy the adbkey of the workspace to your configuration and restart adb
    
    cd workspace
    cp trustme/build/device_provisioning/test_certificates/dev.user.adbkey ~/.android/adbkey
    adb kill-server
    
Alternatively you can copy your current host adb pub key to the test_certificats folder
and rebuild the userdata image

    cp ~/.android/adbkey.pub \
        trustme/build/device_provisioning/test_certificates/dev.user.adbkey.pub
    cp ~/.android/adbkey \
        trustme/build/device_provisioning/test_certificates/dev.user.adbkey
    make userdata_image
    
### Flash device
#### Unlock hammerhead

In order to be able to flash trust\|me on the hammerhead device the bootloader has to be unlocked:

get device into fastboot mode: "Press and hold both Volume Up and Volume Down, then press and hold Power"

    fastboot oem unlock

#### Flash hammerhead
The adb version needed for make deploy_images is 1.0.32! (usually we build this as part of the overall
trust|me build)  
press "Volume Down" hold it and then additionally press "Power"  
Plugin mobile phone to USB port on PC  

    fastboot flash boot out-trustme/target/hammerhead/boot.img \
        flash recovery out-trustme/target/hammerhead/recovery.img \
        flash userdata out-trustme/target/hammerhead/userdata.img

    fastboot reboot
    make deploy_images
    
#### Change default usertoken password
Now you have deployed a development release to your device. The device generates a user token which
is used to encrypt the container's data with the default password **trustme**.
If you want to use the phone for real user data, you are strongly advised to change the password of this
token before you start any container for the fist time!

```
# get token from device
adb pull /data/cml/tokens/testuser.p12 .
# unwrap token
openssl pkcs12 -in testuser.p12 -out tmpmycert.pem -nodes
# rewrap token
openssl pkcs12 -export -out newtestuser.p12 -in tmpmycert.pem
# remove temp file
rm tmpmycert.pem
# push new token and remove temp tokens
adb push newtestuser.p12 /data/cml/tokens/testuser.p12
rm testuser.p12 newtestuser.p12
```

or just replace the token with the generated test token in
trustme/build/device_provisioning/test_certificates/dev.user.p12
    
    adb push trustme/build/device_provisioning/test_certificates/dev.user.p12 \
        /data/cml/tokens/testuser.p12
