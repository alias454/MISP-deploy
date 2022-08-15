#!/usr/bin/env bash

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

modules_home="/opt/misp_modules"
useradd --system --shell /sbin/nologin --create-home --home "${modules_home}" --user-group misp-modules
mkdir "${modules_home}/source/"

dnf config-manager --set-enabled powertools

# Build required python modules
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    python39-devel \
    python39-wheel \
    zbar \
    gcc \
    gcc-c++ \
    git-core \
    libglvnd-glx \
    poppler-cpp \
    poppler-cpp-devel

# Clean the DNF cache
# dnf clean all

MISP_MODULES_VERSION="${MISP_MODULES_VERSION:-main}"

# Create and activate a virtual python env
python3 -m venv "${modules_home}/.venv"
source "${modules_home}/.venv/bin/activate"

cd "${modules_home}/source/"
COMMIT="$(git ls-remote https://github.com/MISP/misp-modules.git "${MISP_MODULES_VERSION}" | cut -f1)"
curl --proto '=https' --tlsv1.3 --fail -sSL "https://github.com/MISP/misp-modules/archive/${COMMIT}.tar.gz" | tar zx --strip-components=1
python3 -m pip --no-cache-dir install --disable-pip-version-check -r REQUIREMENTS
echo "${COMMIT}" > "${modules_home}/misp-modules-commit"

ln -s "${modules_home}/.venv/bin/misp-modules" "${modules_home}/server"

chown -R misp-modules:misp-modules "${modules_home}"
chmod -R o-rwx "${modules_home}"

# Deactivate virtual environment
deactivate

cat > "/etc/systemd/system/misp-modules.service" <<EOF
[Unit]
Description=Start the misp modules server at boot

[Service]
Type=simple
User=misp-modules
Group=misp-modules
ExecStart=${modules_home}/server -l 127.0.0.1 -p 6666

[Install]
WantedBy=multi-user.target
EOF
