#!/usr/bin/env bash
# Compile PHP modules

set -e
if [[ "${MISP_DEBUG}" == "yes" ]]; then
    set -o xtrace
else
    set +x
fi

function download_and_check () {
    curl --proto '=https' --tlsv1.3 -sS --location --fail -o package.tar.gz "$1"
    echo "$2 package.tar.gz" | sha256sum -c
    tar zxf package.tar.gz --strip-components=1
    rm -f package.tar.gz
}

build_home="${build_home:-/opt/build}"
if [[ ! -d "${build_home}" ]]; then
    mkdir -p "${build_home}"
fi

mkdir "${build_home}/php-modules/"

# Install dev packages for building php modules
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    gcc \
    make \
    php-devel \
    brotli-devel \
    libzstd-devel \
    ssdeep-devel

# Clean the DNF cache
# dnf clean all

# Compile igbinary
mkdir "${build_home}/igbinary" && cd "${build_home}/igbinary"
download_and_check https://github.com/igbinary/igbinary/archive/refs/tags/3.2.7.tar.gz 21863908348f90a8a895c8e92e0ec83c9cf9faffcfd70118b06fe2dca30eaa96
phpize
./configure --silent CFLAGS="-O2 -g" --enable-igbinary
make -j$(nproc)
make install # `make install` is necessary, so redis extension can be compiled with `--enable-redis-igbinary`
mv modules/*.so "${build_home}/php-modules/"

# Compile zstd library and zstd extension
mkdir "${build_home}/zstd" && cd "${build_home}/zstd"
download_and_check https://github.com/kjdev/php-ext-zstd/archive/bf7931996aac9d14ba550783c12070442445d6f2.tar.gz 64d8000c6580ea97d675fc43db6a2a1229e9ad06185c24c60fd4b07e73852fce
cd zstd
download_and_check https://github.com/facebook/zstd/archive/refs/tags/v1.5.2.tar.gz f7de13462f7a82c29ab865820149e778cbfe01087b3a55b5332707abf9db4a6e
cd ..
phpize
./configure --silent
make --silent -j$(nproc)
mv modules/*.so "${build_home}/php-modules/"

# Compile redis
mkdir "${build_home}/redis" && cd "${build_home}/redis"
download_and_check https://github.com/phpredis/phpredis/archive/refs/tags/5.3.7.tar.gz 6f5cda93aac8c1c4bafa45255460292571fb2f029b0ac4a5a4dc66987a9529e6
phpize
./configure --silent --enable-redis-igbinary --enable-redis-zstd
make -j$(nproc)
mv modules/*.so "${build_home}/php-modules/"

# Compile ssdeep
mkdir "${build_home}/ssdeep" && cd "${build_home}/ssdeep"
download_and_check https://github.com/php/pecl-text-ssdeep/archive/refs/tags/1.1.0.tar.gz 256c5c1d6b965f1c6e0f262b6548b1868f4857c5145ca255031a92d602e8b88d
phpize
./configure --silent --with-ssdeep=/usr --with-libdir=lib64
make -j$(nproc)
mv modules/*.so "${build_home}/php-modules/"

# Compile brotli
mkdir "${build_home}/brotli" && cd "${build_home}/brotli"
download_and_check https://github.com/kjdev/php-ext-brotli/archive/refs/tags/0.13.1.tar.gz 1eca1af3208e2f6551064e3f26e771453def588898bfc25858ab1db985363e47
phpize
./configure --silent --with-libbrotli
make -j$(nproc)
mv modules/*.so "${build_home}/php-modules/"

# Compile snuffleupagus
mkdir "${build_home}/snuffleupagus" && cd "${build_home}/snuffleupagus"
download_and_check https://github.com/jvoisin/snuffleupagus/archive/refs/tags/v0.8.2.tar.gz a39767b6f2688c605a0ab804c99379ae5d80cee1fc73f46e736807fed01b135e
cd src
phpize
./configure --silent --enable-snuffleupagus
make -j$(nproc)
mv modules/*.so "${build_home}/php-modules/"

# Remove debug symbols from binaries
strip "${build_home}"/php-modules/*.so

# PHP custom extensions configuration
mv "${build_home}"/php-modules/* /usr/lib64/php/modules/

echo 'extension = brotli.so' > /etc/php.d/40-brotli.ini
echo 'extension = zstd.so' > /etc/php.d/40-zstd.ini
echo 'extension = igbinary.so' > /etc/php.d/40-igbinary.ini
echo 'extension = ssdeep.so' > /etc/php.d/40-ssdeep.ini

cat > /etc/php.d/50-redis.ini <<EOF
extension = redis.so

redis.session.locking_enabled = 1
redis.session.lock_expire = 30
redis.session.lock_wait_time = 50000
redis.session.lock_retries = 30
EOF
