#!/bin/bash

# TODO: make dest not hardcoded

NAME=$1
DEST="/nfs/$NAME"

# remove old nfs filesystem if one exists
rm -rf $DEST

# build a proto image - natty + packages that will install (optimization)
if [ ! -d proto ]; then
    debootstrap natty proto
    cp sources.list proto/etc/apt/sources.list
    chroot proto apt-get update
    chroot proto apt-get install -y `cat apts/* | cut -d\# -f1 | egrep -v "(rabbitmq|libvirt-bin)"`
    chroot proto pip install `cat pips/*`
    git clone https://github.com/cloudbuilders/nova.git proto/opt/nova
    git clone https://github.com/cloudbuilders/openstackx.git proto/opt/openstackx
    git clone https://github.com/cloudbuilders/noVNC.git proto/opt/noVNC
    git clone https://github.com/cloudbuilders/openstack-dashboard.git proto/opt/dash
    git clone https://github.com/cloudbuilders/python-novaclient.git proto/opt/python-novaclient
    git clone https://github.com/cloudbuilders/keystone.git proto/opt/keystone
    git clone https://github.com/cloudbuilders/glance.git proto/opt/glance
fi

cp -pr proto $DEST

# set hostname
echo $NAME > $DEST/etc/hostname
echo "127.0.0.1 localhost $NAME" > $DEST/etc/hosts

# copy kernel modules
cp -pr /lib/modules/`uname -r` $DEST/lib/modules

# copy openstack installer and requirement lists to a new directory.
mkdir -p $DEST/opt
cp stack.sh $DEST/opt/stack.sh
cp -r pips $DEST/opt
cp -r apts $DEST/opt

# injecting root's ssh key
# FIXME: only do this if id_rsa.pub exists
mkdir $DEST/root/.ssh
chmod 700 $DEST/root/.ssh
cp /root/.ssh/id_rsa.pub $DEST/root/.ssh/authorized_keys

# set root password to password
echo root:password | chroot $DEST chpasswd
