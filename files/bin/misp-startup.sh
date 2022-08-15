#!/usr/bin/env bash

set -e

echo "======================================="
echo "MISP SQL Setup - Branch:${MISP_VERSION}"
echo "======================================="

# Generate SQL root password if one does not exist
if [[ -f /root/.sql_credentials ]]; then
    MYSQL_ROOT_PASSWORD="$(cat /root/.sql_credentials)"
else
    MYSQL_ROOT_PASSWORD="$(openssl rand -base64 32)"
    echo "${MYSQL_ROOT_PASSWORD}" | tee /root/.sql_credentials >/dev/null
    chmod 400 /root/.sql_credentials
fi

# Read DB values, which are generated during install
if [[ -f /var/www/MISP/app/Config/database.php ]]; then
    MISP_DB="$(awk -F "'" '/database/ {print $4}' /var/www/MISP/app/Config/database.php)"
    MISP_DB_USER="$(awk -F "'" '/login/ {print $4}' /var/www/MISP/app/Config/database.php)"
    MISP_DB_PASSWORD="$(awk -F "'" '/password/ {print $4}' /var/www/MISP/app/Config/database.php)"
else
    echo "Error: database.php not found! ... Exiting"
    exit 1
fi

# Read ADMIN values, which are generated during install
if [[ -f /var/www/MISP/app/Config/config.php ]]; then
    MISP_ADMIN_EMAIL="$(awk -F "'" '/contact/ {print $4}' /var/www/MISP/app/Config/config.php)"

    # Generate MISP admin password if one does not exist
    if [[ -f /root/.misp_admin_credentials ]]; then
        MISP_ADMIN_PASSWORD="$(cat /root/.misp_admin_credentials)"
    else
        MISP_ADMIN_PASSWORD="$(openssl rand -base64 32)"
        echo "${MISP_ADMIN_PASSWORD}" | tee /root/.misp_admin_credentials >/dev/null
        chmod 400 /root/.misp_admin_credentials
    fi
else
    echo "Error: config.php not found! ... Exiting"
    exit 1
fi

function check_schema() {
    local DB=$1;
    SQL="SELECT count(*) FROM information_schema.tables WHERE table_schema = '${DB}';"
    if [[ $(mysql -N -s -u root -p"${MYSQL_ROOT_PASSWORD}" --execute "${SQL}" ) -gt 0 ]]; then
        echo "Table ${DB} exists! ... Skipping Creation"
        exit 0
    else
        echo "Table ${DB} does not exist! ... Running DB Prep"
    fi
}

check_schema "${MISP_DB}"

# Secure the SQL install
mysql --user=root <<SQL
UPDATE mysql.user SET authentication_string = PASSWORD('${MYSQL_ROOT_PASSWORD}') WHERE User='root';
UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL

# Add MISP DB USER and create empty DB
mysql --user=root -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE DATABASE ${MISP_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${MISP_DB_USER}'@localhost IDENTIFIED BY '${MISP_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MISP_DB}.* TO '${MISP_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

# Setup MISP DB
if [[ -f /data/MISP/backup.sql ]]; then
    # Restore DB from a backup if exists
    mysql --user=root -p"${MYSQL_ROOT_PASSWORD}" "${MISP_DB}" < /data/MISP/backup.sql
else
    # Import DB from MYSQL.sql if new install
    mysql --user=root -p"${MYSQL_ROOT_PASSWORD}" "${MISP_DB}" < /var/www/MISP/INSTALL/MYSQL.sql
fi

# Update DB to latest version
sudo -u apache bash -c "/var/www/MISP/app/Console/cake Admin runUpdates || true"

# Init default admin user
/var/www/MISP/app/Console/cake userInit -q > /dev/null 2>&1

# Set default admin password
/var/www/MISP/app/Console/cake user change_pw --no_password_change admin@admin.test "${MISP_ADMIN_PASSWORD}"

# Set default admin email
mysql --user=root -p"${MYSQL_ROOT_PASSWORD}" "${MISP_DB}" --execute "UPDATE users SET email = '${MISP_ADMIN_EMAIL}' WHERE id = 1;"

# Reset permissions in case anything was mangled
chgrp -R apache /var/www/MISP
chmod -R o-rwx /var/www/MISP

# Update MISP JSON structures
sudo -u apache bash -c "/var/www/MISP/app/Console/cake Admin updateJSON"
