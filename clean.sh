#! /bin/bash

# cleanup!

source vars.sh

read -p "Are you sure you want to delete the keys ($CERTS_DIR and $CONFIG_DIR/${MACH_PREFIX}...)? Ctrl-c to exit now, or hit anything else to proceed  "
echo ""

rm -rf $CERTS_DIR 
rm -rf $CONFIG_DIR/$MACH_PREFIX*

rm -rf proxy1.etcd

mintnet docker -- rm -vf etcd
killall etcd
