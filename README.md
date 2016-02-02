# etcd-launch

Simple script for securely launching an etcd cluster on docker machines

```
./launch.sh
```

Functionality:

- launch some docker machines

- create a CA

- create TLS keys for each machine, signed by the CA

- launch the static etcd cluster with respective keys

- create a proxy cert, sign with CA

- start the proxy with client-side TLS

