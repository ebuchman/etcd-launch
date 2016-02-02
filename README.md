# etcd-launch

Simple script for securely launching an etcd cluster on docker machines

```
./all.sh
```

With inspiration from https://github.com/coreos/etcd/tree/master/hack/tls-setup

# Functionality

- create a CA

- create TLS keys for each machine, signed by the CA

- launch the static etcd cluster with respective keys, and to only respect client keys signed by CA

- create a proxy cert, sign with CA

- start the proxy with client-side TLS

# Dependencies

- docker-machine

- cfssl: `go get github.com/cloudflare/cfssl/cmd/...`

- jq
