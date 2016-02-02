#! /bin/bash

# this is a bash script to 
#	- launch some docker machines
# 	- create a CA
#	- create TLS keys for each machine, signed by the CA
#	- launch the static etcd cluster
#	- create a client cert, sign with CA

N=3

declare -a IPS
declare -a MACHINES

if [[ "$MACH_PREFIX" == "" ]]; then
	MACH_PREFIX="mach"
fi

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

CERTS_DIR=certs
CONFIG_DIR=config

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

echo "CLUSTER: $CLUSTER"

DEPLOY_LOG=.deploylog
mkdir -p $DEPLOY_LOG

for i in `seq 1 $N`; do
	echo " "
	echo " "

	IP=${IPS[$i]}
	MACH=${MACHINES[$i]}
	echo "MACH $MACH"
#	eval $(docker-machine env $MACH)
	#export DOCKER_OPTS="-H $DOCKER_HOST --tls --tlskey $DOCKER_CERT_PATH/server-key.pem    --tlscert $DOCKER_CERT_PATH/server.pem --tlsverify --tlscacert $DOCKER_CERT_PATH/ca.pem "
	echo "IP $IP"

	# copy over the necessary certs and the ca
	NEW_CERTS_DIR="etcd_certs_$MACH"
	docker-machine scp -r $CERTS_DIR/$MACH "${MACH}:${NEW_CERTS_DIR}"
	docker-machine scp -r $CERTS_DIR/ca.pem "${MACH}:${NEW_CERTS_DIR}/ca.pem"

	# docker $DOCKER_OPTS run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 4001:4001 -p 2380:2380 -p 2379:2379 \
	 #--name etcd quay.io/coreos/etcd:v2.2.4 \
	 ETCD_CMD="-name $MACH \
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

	docker-machine ssh $MACH -- ulimit -n 10000\; curl -L  https://github.com/coreos/etcd/releases/download/v2.2.4/etcd-v2.2.4-linux-amd64.tar.gz -o etcd-v2.2.4-linux-amd64.tar.gz \; tar xzvf etcd-v2.2.4-linux-amd64.tar.gz \; ./etcd-v2.2.4-linux-amd64/etcd $ETCD_CMD \&  &> $DEPLOY_LOG/${MACH}.log &
done


# launch the proxy process
MACH_CERT_DIR=$CERTS_DIR/proxy1

etcd -name proxy1 -proxy=on -listen-client-urls https://localhost:8080 -initial-cluster $CLUSTER --cert-file=$MACH_CERT_DIR/proxy1.pem --key-file=$MACH_CERT_DIR/proxy1-key.pem --trusted-ca-file=$MACH_CERT_DIR/ca.pem --peer-cert-file=$MACH_CERT_DIR/proxy1.pem --peer-key-file=$MACH_CERT_DIR/proxy1-key.pem --peer-client-cert-auth --peer-trusted-ca-file=$MACH_CERT_DIR/ca.pem

