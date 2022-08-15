#!/usr/bin/env bash

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

if [[ "${MISP_ATTACHMENT_SCAN_MODULE}" != "clamav" ]]; then
    # Exit cleanly if not using ClamAV scan module
    exit 0
fi

# Install required packages for ClamAV
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    clamav-server-systemd \
    clamav-server \
    clamav-data \
    clamav-update \
    clamav-filesystem \
    clamav-scanner-systemd \
    clamav-devel \
    clamav-lib \
    clamav

# Clean the DNF cache
# dnf clean all

# Check if selinux is installed
if [[ -f /etc/selinux/config ]]; then
    setsebool -P antivirus_can_scan_system 1
    setsebool -P clamd_use_jit 1
fi

# Add misp-modules user to virusgroup to allow scanning attachments
usermod -a -G virusgroup misp-modules

# Enable ClamAV
sed -i -e "s/^Example/#Example/" /etc/clamd.d/scan.conf
sed -i -e "s/^#LocalSocket /LocalSocket /" /etc/clamd.d/scan.conf  # /run/clamd.scan/clamd.sock

# Enable FreshClam
sed -i -e "s/^Example/#Example/" /etc/freshclam.conf

# Run definition update
freshclam

# Only enable services do not try to start them during build
# If the script is running on a VM we can start them
if [[ "${container:-None}" == "docker" ]]; then
    systemctl enable clamd@scan.service
    systemctl enable clamav-freshclam.service
else
    systemctl enable --now clamd@scan.service
    systemctl enable --now clamav-freshclam.service
fi
