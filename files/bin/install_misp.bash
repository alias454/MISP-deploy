#!/usr/bin/env bash

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

# Download MISP
cd /var/www
git config --system http.sslVersion tlsv1.3 # Always use TLSv1.3 or better for git operations

echo -e "Cloning MISP branch : ${MISP_VERSION}"
git clone --branch "${MISP_VERSION}" --depth 1 https://github.com/MISP/MISP.git MISP

# Clone submodules under app/files, we don't need the rest
cd /var/www/MISP/app/files/
git submodule update --depth 1 --init --recursive .

# Install MISP composer dependencies
cd /var/www/MISP/app

chown -R apache:apache /var/www/MISP

# Require exact version of `symfony/polyfill-php80` to keep compatibility,
# later version replaces Attribute class :/
sudo -u apache bash -c "php composer.phar --no-cache require --update-no-dev \
    symfony/polyfill-php80:v1.18.1 \
    jakub-onderka/openid-connect-php:1.0.0 \
    cakephp/cakephp:2.10.24 \
    supervisorphp/supervisor \
    guzzlehttp/guzzle \
    sentry/sdk \
    php-http/message"

# Remove unused packages
sudo -u apache bash -c "php composer.phar --no-cache remove --update-no-dev \
    monolog/monolog \
    kamisama/cake-resque"

# Create attachments folder
mkdir -p /var/www/MISP/app/attachments

# Set permissions
chown -R root:apache /var/www/MISP
chmod -R g+r,o= /var/www/MISP

find /var/www/MISP -type d -exec chmod u+rx,g+rx,o= {} \;
chown -R apache:apache /var/www/MISP/app/tmp
chown -R apache:apache /var/www/MISP/app/files
chown -R apache:apache /var/www/MISP/app/attachments
chown -R apache:apache /var/www/MISP/app/webroot/

mkdir -p /var/www/MISP/app/Config/
mv "${CONFIG_DIR}"/Config/* /var/www/MISP/app/Config/
chown -R apache:apache /var/www/MISP/app/Config/
chmod u=r,g=r,o= /var/www/MISP/app/Config/*

# Service to finish MISP install
cat > "/usr/lib/systemd/system/misp-sql-setup.service" <<EOF
[Unit]
Description=Misp OneShot SQL Setup
Requires=mysqld.service
After=mysqld.service

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/local/bin/misp-startup.sh
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

# Create alias to cake console command
echo 'alias cake="/var/www/MISP/app/Console/cake"' >> /root/.bashrc
