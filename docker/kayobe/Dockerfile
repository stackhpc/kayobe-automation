# syntax=docker/dockerfile:1.2

# NOTE: Currently supported images:
# quay.io/rockylinux/rockylinux:8
# rockylinux:9
ENV PIP_CERT=/etc/pki/tls/certs/ca-bundle.trust.crt
ENV HTTP_PROXY=http://192.168.121.250:3127
ENV HTTPS_PROXY=http://192.168.121.250:3127
ENV NO_PROXY=localhost,127.0.0.1,10.1.1.1,192.168.121.111,192.168.124.111,192.168.121.112,192.168.124.112,192.168.121.113,192.168.124.113,192.168.121.114,192.168.124.114,192.168.121.115,192.168.124.115,192.168.121.116,192.168.121.25,192.168.124.116,192.168.121.117,192.168.124.117,192.168.121.118,192.168.124.118,192.168.121.250,192.168.121.253,192.168.121.254,192.168.121.11,192.168.121.12,192.168.121.13,192.168.121.16,192.168.121.31,192.168.121.33,192.168.121.34,192.168.121.36,192.168.121.37,192.168.121.23,192.168.121.24,192.168.123.15,192.168.123.16,192.168.123.17,192.168.123.18,192.168.123.19,192.168.123.20,192.168.123.21,192.168.123.22,192.168.134.11,192.168.134.12,192.168.134.13,192.168.134.14,192.168.134.15,192.168.134.16,192.168.134.17,192.168.134.18,192.168.134.10,192.168.123.249,10.69.176.85,dashboard.pengu-cloud.cymru.nhs.uk,identity.pengu-cloud.cymru.nhs.uk,image.pengu-cloud.cymru.nhs.uk,compute.pengu-cloud.cymru.nhs.uk,vnc.pengu-cloud.cymru.nhs.uk,block-storage.pengu-cloud.cymru.nhs.uk,network.pengu-cloud.cymru.nhs.uk,key-manager.pengu-cloud.cymru.nhs.uk,placement.pengu-cloud.cymru.nhs.uk,opensearch-dashboards.pengu-cloud.cymru.nhs.uk,alertmanager.pengu-cloud.cymru.nhs.uk,grafana.pengu-cloud.cymru.nhs.uk,load-balancer.pengu-cloud.cymru.nhs.uk
ENV http_proxy=http://192.168.121.250:3127
ENV https_proxy=http://192.168.121.250:3127
ENV no_proxy=localhost,127.0.0.1,10.1.1.1,192.168.121.111,192.168.124.111,192.168.121.112,192.168.124.112,192.168.121.113,192.168.124.113,192.168.121.114,192.168.124.114,192.168.121.115,192.168.124.115,192.168.121.116,192.168.121.25,192.168.124.116,192.168.121.117,192.168.124.117,192.168.121.118,192.168.124.118,192.168.121.250,192.168.121.253,192.168.121.254,192.168.121.11,192.168.121.12,192.168.121.13,192.168.121.16,192.168.121.31,192.168.121.33,192.168.121.34,192.168.121.36,192.168.121.37,192.168.121.23,192.168.121.24,192.168.123.15,192.168.123.16,192.168.123.17,192.168.123.18,192.168.123.19,192.168.123.20,192.168.123.21,192.168.123.22,192.168.134.11,192.168.134.12,192.168.134.13,192.168.134.14,192.168.134.15,192.168.134.16,192.168.134.17,192.168.134.18,192.168.134.10,192.168.123.249,10.69.176.85,dashboard.pengu-cloud.cymru.nhs.uk,identity.pengu-cloud.cymru.nhs.uk,image.pengu-cloud.cymru.nhs.uk,compute.pengu-cloud.cymru.nhs.uk,vnc.pengu-cloud.cymru.nhs.uk,block-storage.pengu-cloud.cymru.nhs.uk,network.pengu-cloud.cymru.nhs.uk,key-manager.pengu-cloud.cymru.nhs.uk,placement.pengu-cloud.cymru.nhs.uk,opensearch-dashboards.pengu-cloud.cymru.nhs.uk,alertmanager.pengu-cloud.cymru.nhs.uk,grafana.pengu-cloud.cymru.nhs.uk,load-balancer.pengu-cloud.cymru.nhs.uk

ARG BASE_IMAGE="quay.io/rockylinux/rockylinux:8"
FROM ${BASE_IMAGE}
LABEL maintainer="Will Szumski will@stackhpc.com"

# Unclear at this time if different environments will change
# control host bootstrap.
ARG KAYOBE_ENVIRONMENT=""
ARG KAYOBE_DOCKER_SSH_CONFIG_PATH=".automation/docker/kayobe/ssh_config"
ARG KAYOBE_DOCKER_PIP_CONFIG_PATH=".automation/docker/kayobe/pip.conf"

ENV container docker
# NOTE: systemd requires privileged container
# RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
# systemd-tmpfiles-setup.service ] || rm -f $i; done); \
# rm -f /lib/systemd/system/multi-user.target.wants/*;\
# rm -f /etc/systemd/system/*.wants/*;\
# rm -f /lib/systemd/system/local-fs.target.wants/*; \
# rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
# rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
# rm -f /lib/systemd/system/basic.target.wants/*;\
# rm -f /lib/systemd/system/anaconda.target.wants/*;
# VOLUME [ "/sys/fs/cgroup" ]

# CMD ["/usr/sbin/init"]

COPY .automation/docker/kayobe/ZscalerRootCertificate-2048-SHA256.pem /etc/pki/ca-trust/source/anchors/ZscalerRootCertificate-2048-SHA256.pem
RUN update-ca-trust extract

ARG BASE_IMAGE="quay.io/rockylinux/rockylinux:8"
ARG USE_PYTHON_312="false"
RUN dnf install epel-release -y && \
    dnf update -y --nobest && \
    if [ "$USE_PYTHON_312" = "true" ] ; then \
        dnf -y install python3.12 && \
        ln -sf /bin/python3.12 /bin/python3 && \
        python3 -m ensurepip ; fi && \
    dnf install -y gcc git vim python3-pyyaml findutils\
        libffi-devel sudo which openssh-server e2fsprogs \
        diffstat diffutils debootstrap procps-ng gdisk util-linux \
        dosfstools lvm2 kpartx systemd-udev bash-completion rsync \
        python3-libselinux jq && \
    if [ "$(grep "^PRETTY_NAME=\"Rocky Linux 9" /etc/os-release)" ] ; then \
    dnf install -y python3 python3-pip iproute ; else \
    dnf install -y python3-virtualenv ; fi && \
    dnf clean all

# Configure lvm not to use udev for device discovery. This allows you to use
# lvm in docker.
# https://serverfault.com/questions/802766/calling-lvcreate-from-inside-the-container-hangs
RUN sed -i 's/# udev_rules = 1/udev_rules = 0/g' /etc/lvm/lvm.conf && \
    sed  -i 's/# udev_sync = 1/udev_sync = 0/g' /etc/lvm/lvm.conf

RUN python3 -m pip install docker six

ENV KAYOBE_USER=stack
ARG KAYOBE_USER_UID=1000
ARG KAYOBE_USER_GID=1000

RUN groupadd -g $KAYOBE_USER_GID -o stack &&  \
    useradd -u $KAYOBE_USER_UID -g $KAYOBE_USER_GID \
    -G wheel -m -d /stack \
    -o -s /bin/bash stack
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN echo export https_proxy=$https_proxy >> /etc/environment && \
    echo export http_proxy=$http_proxy >> /etc/environment && \
    echo export PIP_CERT=/etc/pki/tls/certs/ca-bundle.trust.crt >> /etc/environment
RUN echo export https_proxy=$https_proxy >> /root/.bashrc && \
    echo export http_proxy=$http_proxy >> /root/.bashrc

RUN python3 -m venv /opt/crudini && /opt/crudini/bin/pip install crudini===0.9.3 && \
    ln -s /opt/crudini/bin/crudini /usr/bin/crudini

WORKDIR /stack
USER stack

RUN echo export https_proxy=$https_proxy >> $HOME/.bashrc && \
    echo export http_proxy=$http_proxy >> $HOME/.bashrc

RUN mkdir /stack/.pip && chmod 700 /stack/.pip

RUN echo "[global]" >> /stack/.pip/pip.conf && \
    echo "proxy = $https_proxy" >> /stack/.pip/pip.conf

COPY $KAYOBE_DOCKER_PIP_CONFIG_PATH /etc/pip.conf

RUN mkdir /stack/.ssh && chmod 700 /stack/.ssh
COPY --chown=stack:stack $KAYOBE_DOCKER_SSH_CONFIG_PATH /stack/.ssh/config
RUN chmod 600 /stack/.ssh/config

# Copy custom binaries into image. The wildcard worksaround the check on the parent directory existing.
COPY .automation/utils/kayobe-automation-activate .automation.conf/docker*/kayobe/bin/* /usr/local/bin/

# Control host bootsrap without leaving kayobe-config in the image
RUN --mount=type=ssh,uid=1000 --mount=type=tmpfs,target=/tmp/src --mount=type=bind,source=.,target=/src sudo cp -rfp /src /tmp/ && \
  sudo chown -Rf stack:stack /tmp/src && \
  # Strip the secrets so that we don't need to pass in a vault-password
  grep -lR "\$ANSIBLE_VAULT" /tmp/src | xargs rm -f && \
  bash /tmp/src/.automation/utils/kayobe-automation-install && \
  (rm -f /stack/.ssh/{id_rsa,id_rsa.pub} || true) && \
  (mkdir /stack/.ansible || true) && \
  (cp -rfp /stack/kayobe-automation-env/src/kayobe-config/etc/kayobe/ansible/roles /stack/.ansible/kayobe-automation-roles || true) && \
  (cp -rfp /stack/kayobe-automation-env/src/kayobe-config/etc/kayobe/ansible/collections /stack/.ansible/kayobe-automation-collections || true) && \
  rm -rf /stack/kayobe-automation-env/src/kayobe-config

# Symlinking to /src would create a link within the empty directory
RUN sudo rmdir /src || true

ENV ANSIBLE_ROLES_PATH="/stack/.ansible/kayobe-automation-roles:/stack/kayobe-automation-env/src/kayobe/ansible/roles:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles"
ENV ANSIBLE_COLLECTIONS_PATH="/stack/.ansible/kayobe-automation-collections:/stack/kayobe-automation-env/src/kayobe/ansible/collections:~/.ansible/collections:/usr/share/ansible/collections"
