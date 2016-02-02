#! /bin/bash

# launch the etcd cluster on the machines

source vars.sh

declare -a IPS
declare -a MACHINES

# get IPs 
for i in `seq 1 $N`; do
	MACH="${MACH_PREFIX}${i}"
	IP=`docker-machine ip $MACH`
	IPS[$i]=$IP
	MACHINES[$i]=$MACH
	CLUSTER="${CLUSTER}${MACH}=https://$IP:2380,"
done
# remove last comma
CLUSTER="${CLUSTER::-1}"

for i in `seq 1 $N`; do
	echo " "
	echo " "

	IP=${IPS[$i]}
	MACH=${MACHINES[$i]}
	echo "MACH $MACH"
	echo "IP $IP"

	# copy over the necessary certs and the ca
	MACH_CERTS_DIR="etcd_certs_$MACH"
	docker-machine scp -r $CERTS_DIR/$MACH/. "${MACH}:${MACH_CERTS_DIR}"
	docker-machine scp -r $CERTS_DIR/ca.pem "${MACH}:${MACH_CERTS_DIR}/ca.pem"

	# location in container
	NEW_CERTS_DIR=/$MACH_CERTS_DIR

	ETCD_CMD="docker run -d -v \$(pwd)/$MACH_CERTS_DIR:$NEW_CERTS_DIR -p 4001:4001 -p 2380:2380 -p 2379:2379 \
	 --name etcd quay.io/coreos/etcd:v2.2.4 \
	 -name $MACH \
	 -advertise-client-urls https://$IP:2379,https://$IP:4001 \
	 -listen-client-urls https://0.0.0.0:2379,https://0.0.0.0:4001 \
	 -initial-advertise-peer-urls https://$IP:2380 \
	 -listen-peer-urls https://0.0.0.0:2380 \
	 -initial-cluster-token etcd-cluster-1 \
	 -initial-cluster $CLUSTER \
	 -initial-cluster-state new \
   	 --cert-file=$NEW_CERTS_DIR/${MACH}.pem --key-file=$NEW_CERTS_DIR/${MACH}-key.pem \
	 --peer-cert-file=$NEW_CERTS_DIR/${MACH}.pem --peer-key-file=$NEW_CERTS_DIR/${MACH}-key.pem \
	 --peer-client-cert-auth --peer-trusted-ca-file=$NEW_CERTS_DIR/ca.pem"

	# docker-machine ssh $MACH -- ulimit -n 10000\; curl -L  https://github.com/coreos/etcd/releases/download/v2.2.4/etcd-v2.2.4-linux-amd64.tar.gz -o etcd-v2.2.4-linux-amd64.tar.gz \; tar xzvf etcd-v2.2.4-linux-amd64.tar.gz \; ./etcd-v2.2.4-linux-amd64/etcd $ETCD_CMD \&  &> $DEPLOY_LOG/${MACH}.log &
	docker-machine ssh $MACH -- $ETCD_CMD
done


echo "Done launching etcd cluster"
