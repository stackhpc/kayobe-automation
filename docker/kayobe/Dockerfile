# syntax=docker/dockerfile:1.2

FROM quay.io/centos/centos:stream8
MAINTAINER "Will Szumski" <will@stackhpc.com>

# Unclear at this time if different environments will change
# control host bootstrap.
ARG KAYOBE_ENVIRONMENT=""
ARG KAYOBE_DOCKER_SSH_CONFIG_PATH=".automation/docker/kayobe/ssh_config"

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

RUN dnf install epel-release -y && \
    dnf update -y --nobest && \
    dnf install -y gcc git vim python3-pyyaml python3-virtualenv \
        libffi-devel sudo which openssh-server e2fsprogs rsync \
        diffstat diffutils debootstrap procps-ng gdisk util-linux \
        dosfstools lvm2 kpartx systemd-udev bash-completion && \
    dnf clean all

# Configure lvm not to use udev for device discovery. This allows you to use
# lvm in docker.
# https://serverfault.com/questions/802766/calling-lvcreate-from-inside-the-container-hangs
RUN sed -i 's/# udev_rules = 1/udev_rules = 0/g' /etc/lvm/lvm.conf && \
    sed  -i 's/# udev_sync = 1/udev_sync = 0/g' /etc/lvm/lvm.conf

# Workaround: rsync: --sparse-block=1024: unknown option
# Hoepfully they have fixed this issue before this old
# package is removed.
# See: https://bugzilla.redhat.com/show_bug.cgi?id=2043753
RUN dnf install -y rsync-3.1.3-14.el8 && dnf clean all

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
COPY .automation/utils/* .automation.conf/docker*/kayobe/bin/* /usr/local/bin

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
RUN sudo rmdir /src

ENV ANSIBLE_ROLES_PATH="/stack/.ansible/kayobe-automation-roles:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles"
ENV ANSIBLE_COLLECTIONS_PATH="/stack/.ansible/kayobe-automation-collections:~/.ansible/collections:/usr/share/ansible/collections"
