#!/usr/bin/env bash

set -e
set +x

# Change values for production deployments
export MYSQL_HOST="localhost"
export MISP_DB="misp"
export MISP_DB_USER="misp"

export MISP_VERSION="2.4"  # 2.4 is latest
export MISP_ORG="Testing org"
export MISP_BASEURL="https://localhost"
export MISP_MODULE_URL="http://localhost"
export MISP_ADMIN_EMAIL="admin@local.test"
export SECURITY_SALT="oeHcJOPxTCtwlkPlMnO6G5gG2HKtwKOaQod65jdZ6M"
export SECURITY_ADVANCED_AUTHKEYS="true"
export MISP_ATTACHMENT_SCAN_MODULE="clamav"

export REDIS_HOST="localhost"
export ZEROMQ_ENABLED="yes"

# Used for self signed cert
export SELF_SIGNED_ENABLED="yes"  # Create a self-signed cert
export CERT_COUNTRY="US"          # Country code US, GB, etc
export CERT_STATE="IL"            # State or Province
export CERT_LOCALE="Chicago"      # Locale
export CERT_ORG="${MISP_ORG}"     # Org
export CERT_OU="Security"         # Org Unit
export CERT_CN="localhost"        # Host address
export CERT_SAN="IP:127.0.0.1"    # Subject Alternate name IP: or DNS: Multiple values can be separated by commas
