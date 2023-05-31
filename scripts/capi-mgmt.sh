#!/bin/bash
# # Install `kubectl` CLI

sudo dnf clean all && sudo dnf update 

curl -fsLo /tmp/kubectl "https://dl.k8s.io/release/$(curl -fsL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl

# Install k3s
curl -fsL https://get.k3s.io | sudo bash -s - --disable traefik

# copy kubeconfig file into standard location
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $USER $HOME/.kube/config

# Install helm
curl -fsL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install cert manager
helm upgrade cert-manager cert-manager \
--install \
--namespace cert-manager \
--create-namespace \
--repo https://charts.jetstack.io \
--version v1.11.1 \
--set installCRDs=true \
--wait

# Install Cluster API resources
mkdir -p capi
cat <<EOF > capi/kustomization.yaml
---
resources:
- https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.3.3/cluster-api-components.yaml
- https://github.com/kubernetes-sigs/cluster-api-provider-openstack/releases/download/v0.7.1/infrastructure-components.yaml
patches:
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/args
        value:
          - --leader-elect
          - --metrics-bind-addr=localhost:8080
    target:
      kind: Deployment
      namespace: capi-system
      name: capi-controller-manager
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/args
        value:
          - --leader-elect
          - --metrics-bind-addr=localhost:8080
    target:
      kind: Deployment
      namespace: capi-kubeadm-bootstrap-system
      name: capi-kubeadm-bootstrap-controller-manager
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/args
        value:
          - --leader-elect
          - --metrics-bind-addr=localhost:8080
    target:
      kind: Deployment
      namespace: capi-kubeadm-control-plane-system
      name: capi-kubeadm-control-plane-controller-manager
EOF
kubectl apply -k capi

# Install addon manager
helm upgrade cluster-api-addon-provider cluster-api-addon-provider \
--install \
--repo https://stackhpc.github.io/cluster-api-addon-provider \
--version 0.1.0-dev.0.main.26 \
--namespace capi-addon-system \
--create-namespace \
--wait \
--timeout 30m

sudo dnf install -y python3-pip

sudo pip3 install python-magnumclient kubernetes