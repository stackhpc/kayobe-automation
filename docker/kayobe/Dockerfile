# syntax=docker/dockerfile:1.2

FROM quay.io/rockylinux/rockylinux:9
MAINTAINER "Will Szumski" <will@stackhpc.com>

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

# RUN sed -i -e 's/^mirrorlist/#mirrorlist/g' \
#         -e 's/^#baseurl/baseurl/g' \
#         -e 's/mirror\.centos\.org/vault.centos.org/g' /etc/yum.repos.d/CentOS-Stream-*.repo

RUN dnf config-manager --set-enabled epel \
    dnf update -y && \
    dnf install -y gcc git vim python3-pyyaml python3-virtualenv libffi-devel sudo which openssh-server \
        diffstat diffutils && \
    dnf clean all

RUN dnf install -y socat && dnf clean all

ENV KAYOBE_USER=stack
ARG KAYOBE_USER_UID=1000
ARG KAYOBE_USER_GID=1000

RUN groupadd -g $KAYOBE_USER_GID -o stack &&  \
    useradd -u $KAYOBE_USER_UID -g $KAYOBE_USER_GID \
    -G wheel -m -d /stack \
    -o -s /bin/bash stack
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN python3 -m venv /opt/crudini && /opt/crudini/bin/pip install crudini===0.9.3 && \
    ln -s /opt/crudini/bin/crudini /usr/bin/crudini

WORKDIR /stack
USER stack

RUN mkdir /stack/.ssh && chmod 700 /stack/.ssh
COPY --chown=stack:stack ssh_config /stack/.ssh/config
RUN chmod 600 /stack/.ssh/config
