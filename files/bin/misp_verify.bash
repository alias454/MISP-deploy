#!/usr/bin/env bash

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

# Check if PHP is properly configured
php -v

# Build test
cd /var/www/MISP/tests/
bash build-test.sh

function check_jinja_template () {
  python3 -c 'import sys, jinja2; env = jinja2.Environment(); template = open(sys.argv[1]).read(); env.parse(template); sys.exit(0)' $1
}

check_jinja_template /etc/httpd/conf.d/misp.conf
check_jinja_template /var/www/MISP/app/Config/config.php
check_jinja_template /var/www/MISP/app/Config/database.php
check_jinja_template /var/www/MISP/app/Config/email.php

# Check syntax errors in generated config files
php -l /var/www/MISP/app/Config/config.php
php -l /var/www/MISP/app/Config/database.php
php -l /var/www/MISP/app/Config/email.php

# Check syntax of Apache configs
apachectl -t

# Check syntax of PHP-FPM config
php-fpm --test
