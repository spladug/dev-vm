#!/bin/bash -e

BASE=$(dirname $(readlink -f $0))
RELEASE=$1
DOMAIN_NAME=$2

if [[ "x$RELEASE" = "x" || "x$DOMAIN_NAME" = "x" ]]; then
    echo "USAGE: $0 RELEASE NAME"
    exit 1
fi

TEMPLATE=$(mktemp)

# clean up our temp files on exit
trap clean_up EXIT
function clean_up {
    rm -f $TEMPLATE
}

# make our own domain template based on the uvtool default with the passthrough
# filesystem configuration added
xmlstarlet ed \
    -s '/domain/devices' -t 'elem' -n 'passthrough-filesystem' \
    -i '//passthrough-filesystem' -t 'attr' -n 'type' -v 'mount' \
    -i '//passthrough-filesystem' -t 'attr' -n 'accessmode' -v 'squash' \
    -s '//passthrough-filesystem' -t 'elem' -n 'source' \
    -i '//passthrough-filesystem/source' -t 'attr' -n 'dir' -v "/home/$USER/src" \
    -s '//passthrough-filesystem' -t 'elem' -n 'target' \
    -i '//passthrough-filesystem/target' -t 'attr' -n 'dir' -v 'src-passthrough' \
    -s '//passthrough-filesystem' -t 'elem' -n 'readonly' \
    -r '//passthrough-filesystem' -v 'filesystem' \
    /usr/share/uvtool/libvirt/template.xml > $TEMPLATE

# kick off creation of the vm
uvt-kvm create \
    --template $TEMPLATE \
    --package avahi-daemon \
    --run-script-once $BASE/bootstrap.sh \
    $DOMAIN_NAME release=$RELEASE

# wait for it to finish
echo "creating domain $DOMAIN_NAME..."
uvt-kvm wait --insecure $DOMAIN_NAME 2> /dev/null
echo "done!"
