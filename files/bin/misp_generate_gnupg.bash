#!/usr/bin/env bash

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

# Read ADMIN values, which are generated during install
if [[ -f /var/www/MISP/app/Config/config.php ]]; then
    MISP_ADMIN_EMAIL="$(awk -F "'" '/contact/ {print $4}' /var/www/MISP/app/Config/config.php)"
    GNUPG_PRIVATE_KEY_PASSWORD="$(awk -F "'" '/\x27password\x27/ {print $4}' /var/www/MISP/app/Config/config.php)"
else
    echo "Error: config.php not found! ... Exiting"
    exit 1
fi

# Create gnupg dir under apache user
mkdir -p /var/www/MISP/.gnupg
chown -R apache:apache /var/www/MISP/.gnupg
chmod 700 /var/www/MISP/.gnupg

# Set defaults for autogenerated key
read -r -d '' gen_key_defaults <<EOF || true
    %echo Generating a default key
    Key-Type: default
    Key-Length: 4096
    Subkey-Type: default
    Name-Real: Auto-generated Key
    Name-Comment: MISP Admin Auto-generated Key
    Name-Email: ${MISP_ADMIN_EMAIL}
    Expire-Date: 0
    Passphrase: ${GNUPG_PRIVATE_KEY_PASSWORD}
    # Do a commit here, so that we can later print "done"
    %commit
    %echo done
EOF

# Generate Admin GPG key for a MISP deployment
sudo -u apache bash -c "gpg --homedir /var/www/MISP/.gnupg --batch --gen-key <<< '${gen_key_defaults}'"

# List out existing keys
sudo -u apache bash -c "gpg --homedir /var/www/MISP/.gnupg --list-keys"

# Export public key to the webroot
sudo -u apache bash -c "gpg --homedir /var/www/MISP/.gnupg --export --armor  ${MISP_ADMIN_EMAIL} > /var/www/MISP/app/webroot/gpg.asc"
