# syntax=docker/dockerfile:1.2

FROM centos:8
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

RUN dnf update -y && \
    dnf install -y gcc git vim python3-pyyaml python3-virtualenv \
        libffi-devel sudo which openssh-server e2fsprogs rsync && \
    dnf clean all

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

WORKDIR /stack
USER stack

RUN echo export https_proxy=$https_proxy >> $HOME/.bashrc && \
  echo export http_proxy=$http_proxy >> $HOME/.bashrc

RUN mkdir /stack/.ssh && chmod 700 /stack/.ssh
COPY --chown=stack:stack $KAYOBE_DOCKER_SSH_CONFIG_PATH /stack/.ssh/config
RUN chmod 600 /stack/.ssh/config

COPY --chown=stack:stack . /opt/kayobe-config

ENV PATH="/opt/kayobe-config/.automation/utils:${PATH}"

# Strip the secrets so that we don't need to pass in a vault-password
RUN grep -lR "\$ANSIBLE_VAULT" /opt/kayobe-config | xargs rm

# Copy custom binaries into image. The wildcard worksaround the check on the parent directory existing.
COPY .automation/docker/kayobe/bin/kayobe-automation-workaround-missing .automation.conf/docker*/kayobe/bin/* /usr/local/bin

RUN --mount=type=ssh,uid=1000 USER=stack kayobe-automation-install && rm -rf /stack/kayobe-automation-env/src/kayobe-config
