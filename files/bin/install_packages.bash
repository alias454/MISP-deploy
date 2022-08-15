#!/usr/bin/env bash

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

# Install required packages for build
dnf update -y
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    crypto-policies-scripts \
    dnf-plugins-core \
    bash-completion \
    vim-enhanced \
    colordiff \
    git-core \
    openssl \
    file \
    zip \
    drpm \
    redis \
    cronie \
    rsyslog \
    crontabs \
    supervisor \
    ssdeep-libs

# Install MariaDB support
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    mariadb \
    mariadb-server

cat > "/etc/my.cnf.d/bind-address.cnf" <<EOF
[mysqld]
bind-address=127.0.0.1
EOF

# Install Apache with additional module support
dnf module -y enable mod_auth_openidc
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    httpd \
    mod_ssl \
    mod_auth_openidc

# Remove unnecessary Apache configs
rm -f /etc/httpd/conf.d/userdir.conf
rm -f /etc/httpd/conf.d/welcome.conf
rm -f /etc/httpd/conf.d/ssl.conf

# Remove unnecessary Apache modules
rm -f /etc/httpd/conf.modules.d/01-cgi.conf
rm -f /etc/httpd/conf.modules.d/00-dav.conf
rm -f /etc/httpd/conf.modules.d/00-lua.conf

# Keep proxy and fcgi modules enabled, others are not necessary and generate errors to logs
echo "LoadModule proxy_module modules/mod_proxy.so" > /etc/httpd/conf.modules.d/00-proxy.conf
echo "LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so" >> /etc/httpd/conf.modules.d/00-proxy.conf

# Install PHP 7.4 and additional packages
dnf module enable -y php:7.4
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    php-cli \
    php-fpm \
    php-gd \
    php-mysqlnd \
    php-mbstring \
    php-xml \
    php-bcmath \
    php-opcache \
    php-intl \
    php-gmp \
    php-json \
    php-process \
    php-pecl-apcu \
    php-pecl-xdebug \
    php-pecl-zip

# Set INI path
PHP_INI_PATH="/etc/php.ini"

mkdir /run/php-fpm

# PHP-FPM config
echo 'pm.status_path = /fpm-status' >> /etc/php-fpm.d/www.conf # enable PHP-FPM status page
echo 'listen.acl_users = apache' >> /etc/php-fpm.d/www.conf # `nginx` user doesn't exists
echo 'access.log = /var/log/php-fpm/$pool.access.log' >> /etc/php-fpm.d/www.conf # enable PHP-FPM access log
echo 'access.format = "%R %{HTTP_X_REQUEST_ID}e - %u %t \"%m %r%Q%q\" %s %{mili}d %{kilo}M %C%%"' >> /etc/php-fpm.d/www.conf # change log format

# PHP config
sed -i -e 's/allow_url_fopen = On/allow_url_fopen = Off/' ${PHP_INI_PATH}
sed -i -e 's/;assert.active = On/assert.active = Off/' ${PHP_INI_PATH}
sed -i -e 's/expose_php = On/expose_php = Off/' ${PHP_INI_PATH}
sed -i -e 's/session.sid_length = 26/session.sid_length = 32/' ${PHP_INI_PATH}
sed -i -e 's/session.use_strict_mode = 0/session.use_strict_mode = 1/' ${PHP_INI_PATH}
sed -i -e 's/opcache.enable_cli=1/opcache.enable_cli=0/' /etc/php.d/10-opcache.ini

# Use igbinary serializer for apcu and sessions
sed -i -e 's/session.serialize_handler = php/session.serialize_handler = igbinary/' ${PHP_INI_PATH}
sed -i -e "s/;apc.serializer='php'/apc.serializer='igbinary'/" /etc/php.d/40-apcu.ini

# Disable modules that are not required by MISP
rm -f /etc/php.d/20-ftp.ini
rm -f /etc/php.d/20-shmop.ini
rm -f /etc/php.d/20-sysvmsg.ini
rm -f /etc/php.d/20-sysvsem.ini
rm -f /etc/php.d/20-sysvshm.ini
rm -f /etc/php.d/20-exif.ini

# disable xdebug by default
rm /etc/php.d/15-xdebug.ini

# Install Python 3.9 and additional packages
dnf module enable -y python39
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    python39 \
    python39-pip \
    python39-wheel \
    python39-urllib3 \
    python39-idna \
    python39-lxml \
    python39-ply \
    python39-PyMySQL

alternatives --set python3 /usr/bin/python3.9

python3 -m pip --no-cache-dir install --disable-pip-version-check \
    python-magic \
    pymisp \
    lief \
    plyara \
    pyzmq \
    redis \
    hiredis \
    jinja2 \
    ordered-set \
    pytz \
    pydeep2 \
    simplejson \
    'stix2-patterns>=1.2.0'

# Clean the DNF cache
# dnf clean all
