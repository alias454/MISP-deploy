# Base image
ARG BASE_IMAGE=almalinux:latest
FROM $BASE_IMAGE as base

ENV container docker

# Install systemd -- See https://hub.docker.com/_/centos/
RUN rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN dnf -y install rpm dnf-plugins-core \
 && dnf -y update \
 && dnf -y install \
    initscripts \
    sudo \
    which \
    hostname \
 && dnf clean all

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Test MISP deployment scripts
COPY files/bin/ /tmp/bin/
COPY files/config/ /tmp/config/
COPY files/run_misp_setup.bash /tmp/run_misp_setup.bash

RUN chmod 640 /tmp/bin/ && chmod 640 /tmp/run_misp_setup.bash

ARG CACHEBUST=1
ARG MISP_VERSION=develop
ENV MISP_VERSION $MISP_VERSION

# Install MISP and requirements
RUN bash /tmp/run_misp_setup.bash

# Web server
EXPOSE 80
EXPOSE 443

CMD ["/usr/lib/systemd/systemd"]
