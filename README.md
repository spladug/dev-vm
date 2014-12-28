# dev-vm

This is a set of very small wrappers around `uvtool` to set up development VMs
just how I like them.

In particular, at the moment, this means:

* using ubuntu cloud images
* installing `avahi-daemon` for `*.local` mDNS
* configuring a passthrough filesystem with overlayfs for host/guest code
  sharing

## installation

Install prerequisites:

    sudo apt-get install uvtool xmlstarlet

Download appropriate cloud images. Example:

    uvt-simplestreams-libvirt sync release=precise arch=amd64


## usage

The script is designed to work with Ubuntu Cloud Images that have a default
user of `ubuntu`.

The passthrough filesystem it configures will map `/home/$USER/src` on your
host OS read-only to `/usr/local/src` in the guest.  The guest will then use
overlayfs to put a read-write overlay in `/home/ubuntu/src` allowing build
artifacts etc to live in the vm.

To create a VM, specify the release and the name of the domain:

    ./create-dev-vm.sh precise testvm

Once that's done, you can log in with SSH

    uvt-kvm ssh --insecure testvm

or

    ssh ubuntu@testvm.local

## license

Public domain. See https://creativecommons.org/publicdomain/zero/1.0/.
