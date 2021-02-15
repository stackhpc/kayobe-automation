FROM centos:8
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

RUN dnf update -y && \
    dnf install -y gcc git vim python3-pyyaml python3-virtualenv libffi-devel sudo which openssh-server && \
    dnf clean all

ENV KAYOBE_USER=stack
ARG KAYOBE_USER_UID=1000
ARG KAYOBE_USER_GID=1000

RUN groupadd -g $KAYOBE_USER_GID -o stack &&  \
    useradd -u $KAYOBE_USER_UID -g $KAYOBE_USER_GID \
    -G wheel -m -d /stack \
    -o -s /bin/bash stack
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /stack
USER stack

RUN mkdir /stack/.ssh && chmod 700 /stack/.ssh
COPY --chown=stack:stack ssh_config /stack/.ssh/config
RUN chmod 600 /stack/.ssh/config

