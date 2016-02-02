#! /bin/bash

# generate certificates for each node and the proxy

source vars.sh

declare -a IPS
declare -a MACHINES

# get IPs 
for i in `seq 1 $N`; do
	MACH="${MACH_PREFIX}${i}"
	IP=`docker-machine ip $MACH`
	IPS[$i]=$IP
	MACHINES[$i]=$MACH
done

mkdir -p $CERTS_DIR

# generate the CA key and cert
cfssl gencert -initca $CONFIG_DIR/ca-csr.json | cfssljson -bare $CERTS_DIR/ca

# generate and sign keys for each node
for i in `seq 1 $N`; do
	IP=${IPS[$i]}
	MACH=${MACHINES[$i]}
	MACH_CERTS_DIR=$CERTS_DIR/$MACH
	mkdir -p $MACH_CERTS_DIR
	mkdir -p $CONFIG_DIR/$MACH

	cat $CONFIG_DIR/req-csr.json | jq .hosts[0]=\"$IP\" > "$CONFIG_DIR/$MACH/req-csr-${MACH}.json"
	cfssl gencert \
	  -ca $CERTS_DIR/ca.pem \
	  -ca-key $CERTS_DIR/ca-key.pem \
	  -config $CONFIG_DIR/ca-config.json \
	  -hostname $IP \
	  $CONFIG_DIR/$MACH/req-csr-${MACH}.json | cfssljson -bare $MACH_CERTS_DIR/$MACH
done

# make cert for the proxy node
MACH="proxy1"
MACH_CERTS_DIR=$CERTS_DIR/$MACH
mkdir -p $MACH_CERTS_DIR
cfssl gencert \
  -ca $CERTS_DIR/ca.pem \
  -ca-key $CERTS_DIR/ca-key.pem \
  -config $CONFIG_DIR/ca-config.json \
  -hostname $IP \
  $CONFIG_DIR/req-csr.json | cfssljson -bare $MACH_CERTS_DIR/$MACH
cp $CERTS_DIR/ca.pem $MACH_CERTS_DIR/ca.pem

echo "Done generating certificates for etcd cluster and proxy node"

