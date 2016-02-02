#! /bin/bash

# launch the proxy node locally

source vars.sh
mkdir -p $DEPLOY_LOG


# get IPs 
for i in `seq 1 $N`; do
	MACH="${MACH_PREFIX}${i}"
	IP=`docker-machine ip $MACH`
	CLUSTER="${CLUSTER}${MACH}=https://$IP:2380,"
done
# remove last comma
CLUSTER="${CLUSTER::-1}"

# launch the proxy process
MACH_CERT_DIR=$CERTS_DIR/proxy1

etcd -name proxy1 -proxy=on -listen-client-urls http://localhost:4001 -initial-cluster $CLUSTER --cert-file=$MACH_CERT_DIR/proxy1.pem --key-file=$MACH_CERT_DIR/proxy1-key.pem --trusted-ca-file=$MACH_CERT_DIR/ca.pem --peer-cert-file=$MACH_CERT_DIR/proxy1.pem --peer-key-file=$MACH_CERT_DIR/proxy1-key.pem --peer-client-cert-auth --peer-trusted-ca-file=$MACH_CERT_DIR/ca.pem &> $DEPLOY_LOG/proxy1.log &

echo "Done launching local proxy"
