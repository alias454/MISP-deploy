#!/usr/bin/env bash

# Deploy MISP on a RHEL based OS

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

function get_realpath() {
    # https://stackoverflow.com/a/19250873
    local target="$1"
    [[ ! -f "${target}" ]] && return 1 # failure : file does not exist.
    [[ -n "$no_symlinks" ]] && local pwdp='pwd -P' || local pwdp='pwd' # do symlinks.
    echo "$( cd "${target%/*}" 2>/dev/null; "${pwdp}" )"/"${target##*/}" # echo result.
    return 0 # success
}

function run_script() {
    # Run passed in script
    local RUN_SCRIPT="$1"
    if [[ -f "${RUN_SCRIPT}" ]]; then
        . "${RUN_SCRIPT}"
    fi
}

SCRIPT_PATH="$(dirname "$(get_realpath "$0")")"
RUN_SCRIPTS="${SCRIPT_PATH}/bin"
CONFIG_DIR="${SCRIPT_PATH}/config"

run_script "${RUN_SCRIPTS}/env_settings.bash"
run_script "${RUN_SCRIPTS}/install_packages.bash"
run_script "${RUN_SCRIPTS}/compile_php_modules.bash"
run_script "${RUN_SCRIPTS}/misp_generate_cert.bash"

mv "${RUN_SCRIPTS}/misp-startup.sh" /usr/local/bin/misp-startup.sh
mv "${CONFIG_DIR}/misp.conf" /etc/httpd/conf.d/misp.conf
mv "${CONFIG_DIR}/httpd-errors/"* /var/www/html/
mv "${CONFIG_DIR}/snuffleupagus-misp.rules" /etc/php.d/
mv "${CONFIG_DIR}/supervisor.ini" /etc/supervisord.d/misp.ini
mv "${CONFIG_DIR}/rsyslog.conf" /etc/
mv "${CONFIG_DIR}/logrotate/"* /etc/logrotate.d/
mv "${CONFIG_DIR}/crontab.txt" /etc/crontab

chmod 644 /usr/local/bin/misp-startup.sh
chmod 644 /etc/httpd/conf.d/misp.conf
chmod 644 /etc/php.d/snuffleupagus-misp.rules
chmod 644 /etc/supervisord.d/misp.ini
chmod 644 /etc/rsyslog.conf
chmod 644 /etc/logrotate.d/*
chmod 644 /etc/crontab

# Run the MISP installer and setup configurations
run_script "${RUN_SCRIPTS}/install_misp.bash"

# Run script to populate templates with variable values
python3 "${RUN_SCRIPTS}/misp_create_configs.py"

# Verify everything is deployed as it should be
run_script "${RUN_SCRIPTS}/misp_verify.bash"

# Generate a default GPG encryption key
run_script "${RUN_SCRIPTS}/misp_generate_gnupg.bash"

# Setup misp-modules
run_script "${RUN_SCRIPTS}/install_misp_modules.bash"

# Setup ClamAV
run_script "${RUN_SCRIPTS}/install_clamav.bash"

# Clean the DNF cache
dnf clean all

# Set default crypto policy
update-crypto-policies

# Only enable services do not try to start them during build
# If the script is running on a VM we can start them
if [[ "${container:-None}" == "docker" ]]; then
    systemctl enable httpd.service
    systemctl enable mariadb.service
    systemctl enable redis.service
    systemctl enable supervisord.service
    systemctl enable misp-sql-setup.service
    systemctl enable misp-modules.service
else
    systemctl daemon-reload

    systemctl enable --now httpd.service
    systemctl enable --now mariadb.service
    systemctl enable --now redis.service
    systemctl enable --now supervisord.service
    systemctl enable --now misp-sql-setup.service
    systemctl enable --now misp-modules.service
fi
