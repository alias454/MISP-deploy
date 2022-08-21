#!/usr/bin/env bash

# Script to generate self signed certs for a MISP deployment

#################################################################################
# Environment variables for self signed cert
#  SELF_SIGNED_ENABLED="yes"  # Create a self-signed cert
#  CERT_COUNTRY=US            # Country code US, GB, etc
#  CERT_STATE=IL              # State or Province
#  CERT_LOCALE=Chicago        # Locale
#  CERT_ORG=Test Org          # Org
#  CERT_OU=Test Unit          # Org Unit
#  CERT_CN=localhost          # Host address
#  CERT_SAN="IP:127.0.0.1"    # Subject Alt name IP: or DNS: Use commas for multiple values
#
# Check the cert using - openssl x509 -in cert.crt -text -noout
#                      - openssl verify -CAfile cert.crt cert.crt
#################################################################################

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

SELF_SIGNED_ENABLED=${SELF_SIGNED_ENABLED:-no}
if [[ "${SELF_SIGNED_ENABLED}" == "no" ]]; then
    # Exit cleanly if set to "no"
    echo "Self-signed Certificate not created"
    exit 0
fi

# Set ca_conf path to use with custom certificates 
# and set ca_path value based on OS class
if [[ -f "/etc/pki/tls/openssl.cnf" ]]; then
    # RHEL based systems use this location typically
    ca_conf="/etc/pki/tls/openssl.cnf"
    ca_path="/etc/pki/tls/private/misp"
elif [[ -f "/etc/ssl/openssl.cnf" ]]; then
    # Debian based systems use this location typically
    ca_conf="/etc/pki/tls/openssl.cnf"
    ca_path="/etc/ssl/private/misp"
else
    # No CA conf was found so exit
    echo "No CA configuration file was found"
    exit 1
fi

if [[ ! -d "${ca_path}" ]]; then
    # Create place to store certs
    mkdir -p "${ca_path}"
fi

# Make sure self signed cert isn't marked as a CA
# https://security.stackexchange.com/a/143097
sed -i 's/critical,CA\:true/critical,CA\:false/g' ${ca_conf}

# Set Alternate name option
SAN="${CERT_SAN:-IP:127.0.0.1}"

# Set certificate subject values
C="${CERT_COUNTRY:-US}"      # Country
ST="${CERT_STATE:-IL}"       # State
L="${CERT_LOCALE:-Chicago}"  # Locale
O="${CERT_ORG:-Test Org}"    # Org Name
OU="${CERT_OU:-Dev}"         # Org Unit
CN="${CERT_CN:-localhost}"   # Common DNS name

# Set self-signed tls paths
ca_key_path="${ca_path}/misp-key.pem"
ca_cert_path="${ca_path}/misp-cert.crt"

# Default message for certificate generation
cert_gen_message="Generating self-signed certificate"

# If cert file exists check expiration
if [[ -f "${ca_cert_path}" ]]; then
    seconds=$((60*60*24))
    if openssl x509 -checkend "${seconds}" -noout -in "${ca_cert_path}"; then
        # Exit if not expiring soon
        exit 0
    else
        # Update default message
        cert_gen_message="Regenerating self-signed certificate"
    fi
fi

# Configure self-signed tls
echo "${cert_gen_message}"

# openssl newer than 1.1.1 supports the -addext option
openssl req -new -x509 -newkey rsa:4096 -days 365 -nodes \
-subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}" \
-addext "keyUsage=nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment" \
-addext "extendedKeyUsage=serverAuth" \
-addext "subjectAltName=${SAN}" \
-keyout "${ca_key_path}" -out "${ca_cert_path}"

chown -R root:apache "${ca_path}"
chmod -R 640 "${ca_path}"
