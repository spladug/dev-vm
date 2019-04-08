#!/bin/bash -e

BASE=$(dirname "$(readlink -f "$0")")
DOMAIN_NAME=$1

if [[ "x$DOMAIN_NAME" = "x" ]]; then
    echo "USAGE: $0 NAME"
    exit 1
fi

MEMORY=${MEMORY:-512}
CPUS=${CPUS:-1}
DISK=${DISK:-10}
RELEASE=${RELEASE:-$(lsb_release -sc)}
BOOTSTRAP=${BOOTSTRAP:-$BASE/bootstrap.sh}

TEMPLATE=$(mktemp)
trap clean_up EXIT
function clean_up {
    rm -f "$TEMPLATE"
}

# make our own domain template based on the uvtool default with the passthrough
# filesystem configuration added
xmlstarlet ed \
    -s '/domain' -t 'elem' -n 'cpu' \
    -i '//cpu' -t 'attr' -n 'mode' -v 'host-model' \
    -s '/domain/devices' -t 'elem' -n 'passthrough-filesystem' \
    -i '//passthrough-filesystem' -t 'attr' -n 'type' -v 'mount' \
    -i '//passthrough-filesystem' -t 'attr' -n 'accessmode' -v 'squash' \
    -s '//passthrough-filesystem' -t 'elem' -n 'source' \
    -i '//passthrough-filesystem/source' -t 'attr' -n 'dir' -v "$HOME/src" \
    -s '//passthrough-filesystem' -t 'elem' -n 'target' \
    -i '//passthrough-filesystem/target' -t 'attr' -n 'dir' -v 'src-passthrough' \
    -s '//passthrough-filesystem' -t 'elem' -n 'readonly' \
    -r '//passthrough-filesystem' -v 'filesystem' \
    /usr/share/uvtool/libvirt/template.xml > "$TEMPLATE"

# kick off creation of the vm
uvt-kvm create \
    --template "$TEMPLATE" \
    --package avahi-daemon \
    --memory "${MEMORY}" \
    --cpu "${CPUS}" \
    --disk "${DISK}" \
    --run-script-once "${BOOTSTRAP}" \
    --ssh-public-key-file ~/.ssh/id_vm.pub \
    "$DOMAIN_NAME" release="$RELEASE" arch=amd64

# wait for it to finish
echo "creating domain $DOMAIN_NAME (release=${RELEASE}, mem=${MEMORY} MiB, cpus=${CPUS}, disk=${DISK} GiB, bootstrap=${BOOTSTRAP})"
uvt-kvm wait "$DOMAIN_NAME" 2> /dev/null
echo "done!"
