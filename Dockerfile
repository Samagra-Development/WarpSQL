ARG PG_VERSION
ARG PREV_IMAGE
ARG TS_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.21.0
FROM golang:${GO_VERSION}-alpine AS tools

ENV TOOLS_VERSION 0.8.1

RUN apk update && apk add --no-cache git gcc musl-dev \
    && go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@latest \
    && go install github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy@latest

############################
# Grab old versions from previous version
############################
ARG PG_VERSION
ARG PREV_IMAGE
FROM ${PREV_IMAGE} AS oldversions
# Remove update files, mock files, and all but the last 5 .so/.sql files
RUN rm -f $(pg_config --sharedir)/extension/timescaledb*mock*.sql \
    && if [ -f $(pg_config --pkglibdir)/timescaledb-tsl-1*.so ]; then rm -f $(ls -1 $(pg_config --pkglibdir)/timescaledb-tsl-1*.so | head -n -5); fi \
    && if [ -f $(pg_config --pkglibdir)/timescaledb-1*.so ]; then rm -f $(ls -1 $(pg_config --pkglibdir)/timescaledb-*.so | head -n -5); fi \
    && if [ -f $(pg_config --sharedir)/extension/timescaledb--1*.sql ]; then rm -f $(ls -1 $(pg_config --sharedir)/extension/timescaledb--1*.sql | head -n -5); fi

###########################
# Build pg_search in an environment with dynamic loading
###########################
FROM rust:latest AS pg_search_builder
ARG PG_VERSION

RUN apt-get update && apt-get install -y wget gnupg2 lsb-release

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -


RUN apt-get update && apt-get install -y \
    git \
    postgresql-${PG_VERSION} \
    postgresql-server-dev-${PG_VERSION}     \
    libclang-dev

RUN git clone --branch main https://github.com/paradedb/paradedb.git /paradedb
WORKDIR /paradedb/pg_search

RUN cargo install --locked cargo-pgrx --version 0.11.3

RUN PG_MAJOR_VERSION=$(echo ${PG_VERSION} | cut -d '.' -f 1) && \
    PG_CONFIG_PATH=$(which pg_config) && \
    export PATH=$PATH:/usr/lib/postgresql/${PG_VERSION}/bin && \
    cargo pgrx init --pg${PG_MAJOR_VERSION} ${PG_CONFIG_PATH}


RUN PG_MAJOR_VERSION=$(echo ${PG_VERSION} | cut -d '.' -f 1) && \
    cargo build --release --features "pg${PG_MAJOR_VERSION}"

############################
# Now build image and copy in tools
############################
ARG PG_VERSION
FROM postgres:${PG_VERSION}-alpine3.18
ARG OSS_ONLY

LABEL maintainer="Timescale https://www.timescale.com"

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
COPY --from=oldversions /usr/local/lib/postgresql/timescaledb-*.so /usr/local/lib/postgresql/
COPY --from=oldversions /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/local/share/postgresql/extension/

# copy pg_search
COPY --from=pg_search_builder /paradedb/target/release/libpg_search.so /usr/local/lib/postgresql/
COPY --from=pg_search_builder /paradedb/pg_search/pg_search.control /usr/local/share/postgresql/extension/
COPY --from=pg_search_builder /paradedb/pg_search/sql/*.sql /usr/local/share/postgresql/extension/


ARG TS_VERSION
RUN set -ex \
    && apk add libssl1.1 \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                git \
                openssl \
                openssl-dev \
                tar \
    && mkdir -p /build/ \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \
    \
    && apk add --no-cache --virtual .build-deps \
                coreutils \
                dpkg-dev dpkg \
                gcc \
                krb5-dev \
                libc-dev \
                make \
                cmake \
                util-linux-dev \
    \
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TS_VERSION} \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY} \
    && cd build && make install \
    && cd ~ \
    \
    && if [ "${OSS_ONLY}" != "" ]; then rm -f $(pg_config --pkglibdir)/timescaledb-tsl-*.so; fi \
    && apk del .fetch-deps .build-deps \
    && rm -rf /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample


# Update to shared_preload_libraries
RUN echo "shared_preload_libraries = 'citus,timescaledb,pg_cron,pgautofailover,pg_search'" >> /usr/local/share/postgresql/postgresql.conf.sample

# Adding PG Vector

RUN cd /tmp
RUN apk add --no-cache --virtual .build-deps \
                coreutils \
                dpkg-dev dpkg \
                gcc \
                git \
                krb5-dev \
                libc-dev \
                llvm15 \
                clang \
                clang15 \
                make \
                cmake \
                util-linux-dev \
                && git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git \
                && cd /pgvector \
                && ls \
                && make \
                && make install

# Adding pg_cron 
ARG PG_CRON_VERSION

RUN set -ex \
    && cd /tmp\
    && apk add --no-cache --virtual .pg_cron-deps \
    ca-certificates \
    openssl \
    tar \
    && apk add --no-cache --virtual .pg_cron-build-deps \
    autoconf \
    automake \
    g++ \
    clang15 \
    llvm15 \
    libtool \   
    libxml2-dev \
    make \
    perl \
    && wget -O pg_cron.tar.gz "https://github.com/citusdata/pg_cron/archive/refs/tags/${PG_CRON_VERSION}.tar.gz" \
    && mkdir -p /tmp/pg_cron \
    && tar \
        --extract \
        --file pg_cron.tar.gz \
        --directory /tmp/pg_cron \
        --strip-components 1 \
    && cd /tmp/pg_cron \
    && make \
    && make install \
    # clean
    && cd / \
    && rm /tmp/pg_cron.tar.gz \
    && rm -rf /tmp/pg_cron \
    && apk del .pg_cron-deps .pg_cron-build-deps 

# Add PostGIS Extension
ARG POSTGIS_VERSION

RUN set -eux \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/${POSTGIS_VERSION}.tar.gz" \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        \
        gdal-dev \
        geos-dev \
        proj-dev \
        autoconf \
        automake \
        clang15 \
        cunit-dev \
        file \
        g++ \
        gcc \
        gettext-dev \
        git \
        json-c-dev \
        libtool \
        libxml2-dev \
        llvm15-dev \
        make \
        pcre-dev \
        perl \
        protobuf-c-dev \
    \
# build PostGIS
    \
    && cd /usr/src/postgis \
    && gettextize \
    && ./autogen.sh \
    && ./configure \
        --with-pcredir="$(pcre-config --prefix)" \
    && make -j$(nproc) \
    && make install \
    \
# add .postgis-rundeps
    && apk add --no-cache --virtual .postgis-rundeps \
        \
        gdal \
        geos \
        proj \
        \
        json-c \
        libstdc++ \
        pcre \
        protobuf-c \
        \
        ca-certificates \
# clean
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps 

## Adding Citus

ARG CITUS_VERSION
# Install Citus dependencies 
RUN set -ex \
    && apk add --no-cache --virtual .citus-deps \
    curl \
    jq \
# Install Citus
    && apk add --no-cache --virtual .citus-build-deps \
        gcc \
        libc-dev \
        make \
        curl-dev \
        lz4-dev \
        zstd-dev \
        clang15 \
        krb5-dev \
        icu-dev \
        libxslt-dev \
        libxml2-dev \
        llvm15-dev \
    && CITUS_DOWNLOAD_URL="https://github.com/citusdata/citus/archive/refs/tags/v${CITUS_VERSION}.tar.gz" \
    && curl -L -o /tmp/citus.tar.gz "${CITUS_DOWNLOAD_URL}" \
    && tar -C /tmp -xvf /tmp/citus.tar.gz \
    && chown -R postgres:postgres /tmp/citus-${CITUS_VERSION} \
    && cd /tmp/citus-${CITUS_VERSION} \
    && PATH="/usr/local/pgsql/bin:$PATH" ./configure \
    && make \
    && make install \
    && cd ~ \
    && rm -rf /tmp/citus.tar.gz /tmp/citus-${CITUS_VERSION} \
    && apk del .citus-deps .citus-build-deps



## Adding pg_repack
ARG PG_REPACK_VERSION
RUN set -eux \
    && apk add --no-cache --virtual .pg_repack-build-deps \
        openssl-dev \
        zstd-dev \
        lz4-dev \
        zlib-dev \ 
        make \
        clang15 \
        gawk \
        llvm15 \
        gcc \
        musl-dev \
# build pg_repack
    && wget  -O /tmp/pg_repack-${PG_REPACK_VERSION}.zip "https://api.pgxn.org/dist/pg_repack/${PG_REPACK_VERSION}/pg_repack-${PG_REPACK_VERSION}.zip" \
    && unzip  /tmp/pg_repack-${PG_REPACK_VERSION}.zip -d /tmp \
    && cd /tmp/pg_repack-${PG_REPACK_VERSION} \
    && make \
    && make install \
# clean 
    && cd / \
    && rm -rf /tmp/pg_repack-${PG_REPACK_VERSION} /tmp/pg_repack.zip \
    && apk del .pg_repack-build-deps 

# Adding pgautofailover
ARG PG_AUTO_FAILOVER_VERSION
RUN set -eux \
    && apk add --no-cache --virtual .pg_auto_failover-build-deps \
        make \ 
        gcc \
        musl-dev \
        krb5-dev \ 
        openssl-dev \
        clang15 \ 
        ncurses-dev \
        linux-headers \
        zstd-dev \
        lz4-dev \
        zlib-dev \
        libedit-dev \
        libxml2-utils \
        libxslt-dev \
        llvm15 \
# build pg_auto_failover
    && wget  -O /tmp/pg_auto_failover-${PG_AUTO_FAILOVER_VERSION}.zip "https://github.com/hapostgres/pg_auto_failover/archive/refs/tags/v${PG_AUTO_FAILOVER_VERSION}.zip" \
    && unzip  /tmp/pg_auto_failover-${PG_AUTO_FAILOVER_VERSION}.zip -d /tmp \
    && ls -alh /tmp \
    && cd /tmp/pg_auto_failover-${PG_AUTO_FAILOVER_VERSION} \
    && make \
    && make install \
# clean 
    && cd / \
    && rm -rf /tmp/pg_auto_failove-${PG_AUTO_FAILOVER_VERSION} /tmp/pg_auto_failove-${PG_AUTO_FAILOVER_VERSION}.zip \
    && apk del .pg_auto_failover-build-deps

## Adding postgresql-hll
ARG POSTGRES_HLL_VERSION
RUN set -eux \
    && apk add --no-cache --virtual .postgresql-hll-build-deps \
        openssl-dev \
        zstd-dev \
        lz4-dev \
        zlib-dev \ 
        make \
        git \
        clang15 \
        gawk \
        llvm15 \
        g++ \
        musl-dev \
# build postgresql-hll
    && wget  -O /tmp/postgresql-hll-${POSTGRES_HLL_VERSION}.zip "https://github.com/citusdata/postgresql-hll/archive/refs/tags/v${POSTGRES_HLL_VERSION}.zip" \
    && unzip  /tmp/postgresql-hll-${POSTGRES_HLL_VERSION}.zip -d /tmp \
    && cd /tmp/postgresql-hll-${POSTGRES_HLL_VERSION} \
    && make \
    && make install \
# clean 
    && cd / \
    && rm -rf /tmp/postgresql-hll-${POSTGRES_HLL_VERSION} /tmp/postgresql-hll-${POSTGRES_HLL_VERSION}.zip \
    && apk del .postgresql-hll-build-deps 

# Install pg_jobmon
ARG PG_JOBMON_VERSION
RUN set -e \
    \
    && apk add --no-cache --virtual .pg_jobmon-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && cd /tmp\
    && wget -O pg_jobmon.tar.gz "https://github.com/omniti-labs/pg_jobmon/archive/v$PG_JOBMON_VERSION.tar.gz" \
    && mkdir -p /tmp/pg_jobmon \
    && tar \
        --extract \
        --file pg_jobmon.tar.gz \
        --directory /tmp/pg_jobmon \
        --strip-components 1 \
    \
    && apk add --no-cache --virtual .pg_jobmon-build-deps \
        autoconf \
        automake \
        g++ \
        clang15 \
        llvm15 \
        libtool \
        libxml2-dev \
        make \
        perl \
    && cd /tmp/pg_jobmon \
    && ls -alh . \
    && make \
    && make install \
    && cd / \
    && apk del .pg_jobmon-deps .pg_jobmon-build-deps \
    && rm -rf /tmp/pg_jobmon \
    && rm /tmp/pg_jobmon.tar.gz 

# Adding pg_partman 
ARG PG_PARTMAN_VERSION

RUN set -e \
    && cd /tmp\
    && apk add --no-cache --virtual .pg_partman-deps \
    ca-certificates \
    openssl \
    tar \
    && apk add --no-cache --virtual .pg_partman-build-deps \
    autoconf \
    automake \
    g++ \
    clang15 \
    llvm15 \
    libtool \   
    libxml2-dev \
    make \
    perl \
    && wget -O pg_partman.tar.gz "https://github.com/pgpartman/pg_partman/archive/v$PG_PARTMAN_VERSION.tar.gz" \
    && mkdir -p /tmp/pg_partman \
    && tar \
        --extract \
        --file pg_partman.tar.gz \
        --directory /tmp/pg_partman \
        --strip-components 1 \
    && cd /tmp/pg_partman \
    && make \
    && make install \
    # clean
    && cd / \
    && rm /tmp/pg_partman.tar.gz \
    && rm -rf /tmp/pg_partman \
    && apk del .pg_partman-deps .pg_partman-build-deps 