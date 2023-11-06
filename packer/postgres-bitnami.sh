#! /bin/bash

set -ex 

check_env_variables() {
  for var in "$@"; do
    if [ -z "${!var}" ]; then
      echo "Error: '$var' environment variable is not set."
      exit 1
    fi
  done
}

install_timescaledb (){
    check_env_variables TS_VERSION
    apt-get update 
    apt-get -y install \
            build-essential \
            libssl-dev \
            git \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            cmake \
            wget 
    mkdir -p /build/ 
    git clone https://github.com/timescale/timescaledb /build/timescaledb 
    # Build current version \
    cd /build/timescaledb && rm -fr build 
    git checkout ${TS_VERSION} 
    ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker-bitnami" 
    cd build && make install 
    apt-get autoremove --purge -y \
            \
            build-essential \
            libssl-dev \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            cmake 
    apt-get clean -y 
    rm -rf \
        /build \
        "${HOME}/.cache" \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 
    sed -r -i  's/[#]*\s*(POSTGRESQL_SHARED_PRELOAD_LIBRARIES)\s*=\s*"(.*)"/\1="timescaledb,\2"/;s/,"/"/' /opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh
    
}



install_pgvector(){
# Adding PG Vector
check_env_variables PG_MAJOR
    cd /tmp
    apt-get update
    apt-get install -y --no-install-recommends build-essential git
    git clone --branch v0.4.4 https://github.com/pgvector/pgvector.git /tmp/pgvector
    cd /tmp/pgvector 
    make clean 
    make OPTFLAGS="" 
    make install 
    rm -r /tmp/pgvector 
    apt-get remove -y build-essential git && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*
}

install_citus(){
## Adding Citus
check_env_variables CITUS_VERSION
    apt-get update 
    apt-get install -y curl liblz4-dev libzstd-dev clang libkrb5-dev libicu-dev libxslt1-dev libxml2-dev llvm-dev libcurl4-openssl-dev gawk flex gcc make libssh-dev
    export CITUS_DOWNLOAD_URL="https://github.com/citusdata/citus/archive/refs/tags/v${CITUS_VERSION}.tar.gz" 
    curl -L -o /tmp/citus.tar.gz "${CITUS_DOWNLOAD_URL}" 
    tar -C /tmp -xvf /tmp/citus.tar.gz 
    addgroup --system postgres 
    adduser --system --ingroup postgres --home /opt/bitnami/postgresql --no-create-home postgres 
    chown -R postgres:postgres /tmp/citus-${CITUS_VERSION} 
    cd /tmp/citus-${CITUS_VERSION} 
    PATH="/opt/bitnami/postgresql/bin:$PATH" ./configure 
    make 
    make install 
    cd ~ 
    rm -rf /tmp/citus.tar.gz /tmp/citus-${CITUS_VERSION} 
    apt-get autoremove --purge -y \
            \
            build-essential \
            libssl-dev \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            gawk \
            flex \
            make \
            libssh-dev \
            cmake
    apt-get clean -y 
    rm -rf \
        /build \
        "${HOME}/.cache" \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 
    sed -r -i  's/[#]*\s*(POSTGRESQL_SHARED_PRELOAD_LIBRARIES)\s*=\s*"(.*)"/\1="citus,\2"/;s/,"/"/' /opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh

}

install_postgis(){
# Adding Postgis
check_env_variables POSTGIS_VERSION POSTGIS_SHA256
    cd /tmp
    apt update 
    apt install -y \
        ca-certificates \
        openssl \
        tar \
        wget \
        gettext \
        automake \
        libltdl-dev \
        libxml2-dev \
        libgeos-dev \
        libproj-dev \
        libprotobuf-c-dev \
        protobuf-c-compiler \
        g++\
        gcc \
        make 
    wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/${POSTGIS_VERSION}.tar.gz" 
    echo "${POSTGIS_SHA256} *postgis.tar.gz" | sha256sum -c - 
    mkdir -p /usr/src/postgis 
    tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 
    rm postgis.tar.gz 
# build PostGIS
    cd /usr/src/postgis 
    gettextize 
    ./autogen.sh 
    ./configure \
        --with-pcredir="$(pcre-config --prefix)"  --with-geosconfig="/usr/bin/geos-config"
    make -j$(nproc) 
    make install 
    cd / 
# clean
    apt-get autoremove --purge -y \
        wget \
        g++\
        gcc \
        make 
    apt-get clean -y 
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 
}

install_zombodb(){
# adding zombodb
check_env_variables PG_VER
    cd /tmp
    apt-get update -y -qq --fix-missing 
    apt-get install -y wget gnupg 
    echo "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-14 main" >> /etc/apt/sources.list 
    echo "deb http://security.ubuntu.com/ubuntu bionic-security main" >> /etc/apt/sources.list 
    wget --quiet -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - 
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32 
    apt update 
    apt-get update -y --fix-missing 
    apt-get install -y git curl clang-14 llvm-14 gcc make build-essential libz-dev zlib1g-dev pkg-config libreadline-dev libgdbm-dev libssl1.0-dev
    wget https://www.openssl.org/source/openssl-1.0.2l.tar.gz 
    tar -xzvf openssl-1.0.2l.tar.gz 
    cd openssl-1.0.2l 
    wget https://www.openssl.org/source/openssl-1.0.2l.tar.gz 
    tar -xzvf openssl-1.0.2l.tar.gz 
    cd openssl-1.0.2l 
    ./config 
    make install 
    ln -sf /usr/local/ssl/bin/openssl `which openssl` 
    mkdir ruby  
	cd ruby 
	wget https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz 
	tar xvfz ruby-3.2.2.tar.gz
	cd ruby-3.2.2
	./configure  --with-openssl-dir=/usr/include/openssl-1.0 
	make -j64 
	make install 
    gem install --no-document fpm 
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 
    export PATH="/.cargo/bin:$PATH" 
    export PGRX_HOME="/.pgrx/" 
    mkdir -p $PGRX_HOME 
    cargo install cargo-pgrx --version 0.9.3 
    cargo pgrx init --pg${PG_MAJOR}=/opt/bitnami/postgresql/bin/pg_config 
    git clone https://github.com/zombodb/zombodb.git 
    cd zombodb
    export PATH="/.cargo/bin:$PATH" && cargo pgrx install --release
    cd / 
    apt-get autoremove --purge -y git curl clang-14  gcc make build-essential  wget
    rm -rf .cargo .gem  openssl-1.0.2l .rustup openssl-1.0.2l.tar.gz
    sed -r -i  's/[#]*\s*(POSTGRESQL_SHARED_PRELOAD_LIBRARIES)\s*=\s*"(.*)"/\1="zombodb,\2"/;s/,"/"/' /opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh
}

install_pgrepack(){
## Adding pg_repack
    check_env_variables PG_REPACK_VERSION
    apt-get update
    apt-get install -y  unzip \
        build-essential \
        liblz4-dev \
        zlib1g-dev \
        libssl-dev \
        wget 
# build pg_repack
    wget  -O /tmp/pg_repack-${PG_REPACK_VERSION}.zip "https://api.pgxn.org/dist/pg_repack/${PG_REPACK_VERSION}/pg_repack-${PG_REPACK_VERSION}.zip" 
    unzip  /tmp/pg_repack-${PG_REPACK_VERSION}.zip -d /tmp 
    cd /tmp/pg_repack-${PG_REPACK_VERSION} 
    make 
    make install 
#clean
    apt-get autoremove --purge -y \
        unzip \
        build-essential \
        liblz4-dev \
        libssl-dev \
        wget 
    apt-get clean -y 
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 

}
install_pgautofailover(){
# Adding pgautofailover
    check_env_variables PG_AUTO_FAILOVER_VERSION
    apt-get update 
    apt-get install -y  unzip \
        build-essential \
        liblz4-dev \
        zlib1g-dev \
        libedit-dev \
        libssl-dev \
        libxslt1-dev \
        libxml2-dev \
        wget 
# build pg_auto_failover
    wget  -O /tmp/pg_auto_failover-${PG_AUTO_FAILOVER_VERSION}.zip "https://github.com/hapostgres/pg_auto_failover/archive/refs/tags/v${PG_AUTO_FAILOVER_VERSION}.zip" 
    unzip  /tmp/pg_auto_failover-${PG_AUTO_FAILOVER_VERSION}.zip -d /tmp 
    ls -alh /tmp 
    cd /tmp/pg_auto_failover-${PG_AUTO_FAILOVER_VERSION} 
    make 
    make install 
# clean 
    cd / 
    rm -rf /tmp/pg_auto_failove-${PG_AUTO_FAILOVER_VERSION} /tmp/pg_auto_failove-${PG_AUTO_FAILOVER_VERSION}.zip 
    apt-get autoremove --purge -y \
        unzip \
        build-essential \
        liblz4-dev \
        libedit-dev \
        libssl-dev \
        libxslt1-dev \
        libxml2-dev \
        wget 
    apt-get clean -y 
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 
    sed -r -i  's/[#]*\s*(POSTGRESQL_SHARED_PRELOAD_LIBRARIES)\s*=\s*"(.*)"/\1="pgautofailover,\2"/;s/,"/"/' /opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh

}

install_hll(){
## Adding postgresql-hll
check_env_variables POSTGRES_HLL_VERSION
    apt-get update 
    apt-get install -y  unzip \
        build-essential \
        liblz4-dev \
        zlib1g-dev \
        libedit-dev \
        libssl-dev \
        wget 
# build postgresql-hll
    wget  -O /tmp/postgresql-hll-${POSTGRES_HLL_VERSION}.zip "https://github.com/citusdata/postgresql-hll/archive/refs/tags/v${POSTGRES_HLL_VERSION}.zip" 
    unzip  /tmp/postgresql-hll-${POSTGRES_HLL_VERSION}.zip -d /tmp 
    cd /tmp/postgresql-hll-${POSTGRES_HLL_VERSION} 
    make 
    make install 
# clean 
    cd / 
    rm -rf /tmp/postgresql-hll-${POSTGRES_HLL_VERSION} /tmp/postgresql-hll-${POSTGRES_HLL_VERSION}.zip 
    apt-get autoremove --purge -y \
        unzip \
        build-essential \
        liblz4-dev \
        libedit-dev \
        libssl-dev \
        wget 
    apt-get clean -y 
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 

}

install_pg_jobmon(){
check_env_variables PG_JOBMON_VERSION
set -ex \
    &&apt-get update \
    && apt-get install -y  \
        ca-certificates \
        openssl \
        tar \
        wget \
        autoconf \
        automake \
        g++ \
        clang \
        llvm \
        libtool \
        libxml2-dev \
        make \
        perl \
    \
    && cd /tmp\
    && wget -O pg_jobmon.tar.gz "https://github.com/omniti-labs/pg_jobmon/archive/$PG_JOBMON_VERSION.tar.gz" \
    && mkdir -p /tmp/pg_jobmon \
    && tar \
        --extract \
        --file pg_jobmon.tar.gz \
        --directory /tmp/pg_jobmon \
        --strip-components 1 \
    \
    && cd /tmp/pg_jobmon \
    && make \
    && make install \
    && cd / \
    && apt-get autoremove --purge -y \
        wget \
        autoconf \
        automake \
        clang \
        llvm \
        make \
        perl \
    && apt-get clean -y \
    && rm -rf /tmp/pg_jobmon \
    && rm /tmp/pg_jobmon.tar.gz 
}

install_pg_partman(){
check_env_variables PG_PARTMAN_VERSION
set -ex \
    && cd /tmp\
    && apt-get update \
    && apt-get install -y  \
    ca-certificates \
    openssl \
    tar \
    autoconf \
    automake \
    g++ \
    wget \
    clang \
    llvm \
    libtool \   
    libxml2-dev \
    make \
    perl \
    && wget -O pg_partman.tar.gz "https://github.com/pgpartman/pg_partman/archive/$PG_PARTMAN_VERSION.tar.gz" \
    && mkdir -p /tmp/pg_partman \
    && tar \
        --extract \
        --file pg_partman.tar.gz \
        --directory /tmp/pg_partman \
        --strip-components 1 \
    && cd /tmp/pg_partman \
    && make \
    && make install \
    && cd / \
    && apt-get autoremove --purge -y \
        wget \
        autoconf \
        automake \
        clang \
        llvm \
        make \
        perl \
    && apt-get clean -y \
    && rm /tmp/pg_partman.tar.gz \
    && rm -rf /tmp/pg_partman 
}
# enable contrib extentions
# sed -r -i  's/[#]*\s*(POSTGRESQL_SHARED_PRELOAD_LIBRARIES)\s*=\s*"(.*)"/\1="pg_stat_statements,\2"/;s/,"/"/' /opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh


# Retrieve and split the extension names
IFS=',' read -ra EXTENSION_LIST <<< "$EXTENSIONS"

# Install each extension
for extension in "${EXTENSION_LIST[@]}"; do
    case $extension in
        timescaledb)
            install_timescaledb
            ;;
        pgvector)
            install_pgvector
            ;;
        citus)
            install_citus
            ;;
        postgis)
            install_postgis
            ;;
        zombodb)
            install_zombodb
            ;;
        pg_repack)
            install_pgrepack
            ;;
        pgautofailover)
            install_pgautofailover
            ;;
        hll)
            install_hll
            ;;
        pg_jobmon)
            install_pg_jobmon
            ;;
        pg_partman)
            install_pg_partman
            ;;
        *)
            # Handle unrecognized extensions
            echo "Unknown extension: $extension"
            exit 1
            ;;
    esac
done