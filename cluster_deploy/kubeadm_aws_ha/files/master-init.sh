#!/bin/bash -xe

## Prep System and Install K8s
yum update
yum install -y docker
systemctl enable docker && systemctl start docker

cat <<EOF >  /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
    https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

setenforce 0
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

## Generate and Configure Certs
curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/local/bin/cfssl*

mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd

curl -o ca.pem https://s3-us-west-2.amazonaws.com/bct-jjk3/kubeadm_aws_ha/cacerts/ca.pem
curl -o ca-key.pem https://s3-us-west-2.amazonaws.com/bct-jjk3/kubeadm_aws_ha/cacerts/ca-key.pem
curl -o ca-config.json https://s3-us-west-2.amazonaws.com/bct-jjk3/kubeadm_aws_ha/cacerts/ca-config.json

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client

export PEER_NAME=$(hostname)
export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')

cfssl print-defaults csr > config.json

sed -i '0,/CN/{s/example\.net/'"$PEER_NAME"'/}' config.json
sed -i 's/www\.example\.net/'"$PRIVATE_IP"'/' config.json
sed -i 's/example\.net/'"$PEER_NAME"'/' config.json

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | cfssljson -bare server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | cfssljson -bare peer

## Install etcd
cd /tmp
export ETCD_VERSION=v3.1.10
curl -sSL https://github.com/coreos/etcd/releases/download//etcd--linux-amd64.tar.gz | tar -xzv --strip-components=1 -C /usr/local/bin/
rm -rf etcd--linux-amd64*

