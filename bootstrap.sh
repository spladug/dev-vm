#!/bin/sh

# `ubuntu` this is the default on the ubuntu cloud images
USER=ubuntu

# the directory we will mount the passthrough filesystem
SRC=/home/$USER/src

# ensure it exists and has the correct permissions
mkdir -p $SRC
chown ubuntu:ubuntu $SRC

# add 9p to initrd so mountall can mount these filesystems early on during boot
cat <<END >> /etc/initramfs-tools/modules
9p
9pnet
9pnet_virtio
END
update-initramfs -u

# set up the fstab entries for the passthrough and overlay filesystems
cat <<END >> /etc/fstab
src-passthrough /usr/local/src 9p ro,trans=virtio,version=9p2000.L 0 0
overlayfs $SRC overlayfs lowerdir=/usr/local/src,upperdir=$SRC 0 0
END

# mount them right now
mount /usr/local/src
mount $SRC
