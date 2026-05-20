# syntax=docker/dockerfile:1.2

# Supported image tailored to Ubuntu Noble 24.04
ARG BASE_IMAGE="ubuntu:noble"
FROM ${BASE_IMAGE}
LABEL maintainer="Will Szumski will@stackhpc.com"

# Unclear at this time if different environments will change
# control host bootstrap.
ARG KAYOBE_ENVIRONMENT=""
ARG KAYOBE_DOCKER_SSH_CONFIG_PATH=".automation/docker/kayobe/ssh_config"

ENV container docker

# Suppress interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc git vim findutils libffi-dev sudo \
        which openssh-server e2fsprogs diffstat \
        diffutils debootstrap procps gdisk \
        util-linux dosfstools lvm2 kpartx udev \
        bash-completion rsync jq python3 \
        python3-pip python3-yaml python3-venv \
        python3-apt iproute2 && \
    apt-get clean

# Configure lvm not to use udev for device discovery. This allows you to use
# lvm in docker.
# https://serverfault.com/questions/802766/calling-lvcreate-from-inside-the-container-hangs
RUN sed -i 's/# udev_rules = 1/udev_rules = 0/g' /etc/lvm/lvm.conf && \
    sed  -i 's/# udev_sync = 1/udev_sync = 0/g' /etc/lvm/lvm.conf

# Allow pip installation globally on Ubuntu Noble (PEP 668 bypass)
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN python3 -m pip install docker six

ENV KAYOBE_USER=stack
ARG KAYOBE_USER_UID=1000
ARG KAYOBE_USER_GID=1000

# Ubuntu uses 'sudo' instead of 'wheel'
RUN groupadd -g $KAYOBE_USER_GID -o stack &&  \
    useradd -u $KAYOBE_USER_UID -g $KAYOBE_USER_GID \
    -G sudo -m -d /stack \
    -o -s /bin/bash stack
RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN echo export https_proxy=$https_proxy >> /etc/environment && \
    echo export http_proxy=$http_proxy >> /etc/environment
RUN echo export https_proxy=$https_proxy >> /root/.bashrc && \
    echo export http_proxy=$http_proxy >> /root/.bashrc

RUN python3 -m venv /opt/crudini && /opt/crudini/bin/pip install crudini===0.9.3 && \
    ln -s /opt/crudini/bin/crudini /usr/bin/crudini

WORKDIR /stack
USER stack

RUN echo export https_proxy=$https_proxy >> $HOME/.bashrc && \
    echo export http_proxy=$http_proxy >> $HOME/.bashrc

RUN mkdir /stack/.ssh && chmod 700 /stack/.ssh
COPY --chown=stack:stack $KAYOBE_DOCKER_SSH_CONFIG_PATH /stack/.ssh/config
RUN chmod 600 /stack/.ssh/config

# Copy custom binaries into image. The wildcard worksaround the check on the parent directory existing.
COPY .automation/utils/kayobe-automation-activate .automation.conf/docker*/kayobe/bin/* /usr/local/bin/

# Control host bootstrap without leaving kayobe-config in the image
RUN --mount=type=ssh,uid=1000 --mount=type=tmpfs,target=/tmp/src --mount=type=bind,source=.,target=/src sudo cp -rfp /src /tmp/ && \
    sudo chown -Rf stack:stack /tmp/src && \
    # Strip the secrets so that we don't need to pass in a vault-password
    grep -lR "\$ANSIBLE_VAULT" /tmp/src | xargs rm -f && \
    bash /tmp/src/.automation/utils/kayobe-automation-install && \
    (rm -f /stack/.ssh/{id_rsa,id_rsa.pub} || true) && \
    mkdir -p /stack/.ansible && \
    (cp -rfp /stack/kayobe-automation-env/src/kayobe-config/etc/kayobe/ansible/roles /stack/.ansible/kayobe-automation-roles || true) && \
    (cp -rfp /stack/kayobe-automation-env/src/kayobe-config/etc/kayobe/ansible/collections /stack/.ansible/kayobe-automation-collections || true) && \
    rm -rf /stack/kayobe-automation-env/src/kayobe-config

# Symlinking to /src would create a link within the empty directory
RUN sudo rmdir /src || true

ENV ANSIBLE_ROLES_PATH="/stack/.ansible/kayobe-automation-roles:/stack/kayobe-automation-env/src/kayobe/ansible/roles:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles"
ENV ANSIBLE_COLLECTIONS_PATH="/stack/.ansible/kayobe-automation-collections:/stack/kayobe-automation-env/src/kayobe/ansible/collections:~/.ansible/collections:/usr/share/ansible/collections"