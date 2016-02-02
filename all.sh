#! /bin/bash

# this is a bash script to 
# 	- create a CA
#	- create TLS keys for each machine, signed by the CA
#	- launch the static etcd cluster
#	- create a client cert, sign with CA


bash gen.sh
bash launch.sh
bash proxy.sh
