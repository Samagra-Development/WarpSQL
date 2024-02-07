ARG PG_VERSION
ARG PREV_IMAGE
ARG TS_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.19.1
FROM golang:${GO_VERSION}-alpine AS tools

ENV TOOLS_VERSION 0.8.1

RUN apk update && apk add --no-cache git gcc \
    && go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@latest \
    && go install github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy@latest

############################
# Grab old versions from previous version
############################
ARG PG_VERSION
ARG PREV_IMAGE
FROM ${PREV_IMAGE} AS oldversions
# Remove update files, mock files, and all but the last 5 .so/.sql files.
# There are three types of SQL files, initialization, upgrade, and downgrade,
# which we have to count separately, but it's hard to match with globs, and
# there are also many upgrade/downgrade files per version, so just keep more of
# them.
USER 0

# Docker COPY needs at least one file to copy. If no source is specified, the
# command fails. Create two '.emptyfile' files here to prevent the
# 'COPY --from=oldversions' command below from failing. The files are removed
# after the copy operation is performed.
#
# When the first image for a PG version is created, PREV_IMAGE is set to the
# bitnami upstream image. Therefore, no TimescaleDB files exist and the
# copy commands would fail.
RUN set +o pipefail \
    && rm -vf $(pg_config --sharedir)/extension/timescaledb*mock*.sql \
    && rm -vf $(ls -1tr $(pg_config --pkglibdir)/timescaledb-tsl-*.so | head -n -5) \
    && rm -vf $(ls -1tr $(pg_config --pkglibdir)/timescaledb-[0-9]*.so | head -n -5) \
    && rm -vf $(ls -1tr $(pg_config --sharedir)/extension/timescaledb--*.sql | head -n -20) \
    && { ls $(pg_config --sharedir)/extension/timescaledb--*.sql \
      ; ls $(pg_config --pkglibdir)/timescaledb-*.so \
      ; : ; } \
    && touch $(pg_config --sharedir)/extension/.emptyfile \
    && touch $(pg_config --pkglibdir)/.emptyfile

############################
# Now build image and copy in tools
############################
ARG PG_VERSION
FROM bitnami/postgresql:${PG_VERSION}
ARG PG_VERSION

LABEL maintainer="Timescale https://www.timescale.com"

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
COPY --from=oldversions /opt/bitnami/postgresql/lib/.emptyfile /opt/bitnami/postgresql/lib/timescaledb-*.so /opt/bitnami/postgresql/lib/
COPY --from=oldversions /opt/bitnami/postgresql/share/extension/.emptyfile /opt/bitnami/postgresql/share/extension/timescaledb--*.sql /opt/bitnami/postgresql/share/extension/
COPY bitnami/timescaledb-bitnami-entrypoint.sh /opt/bitnami/scripts/postgresql/

USER 0
ARG TS_VERSION
RUN set -ex \
    && rm -v /opt/bitnami/postgresql/lib/.emptyfile \
    && rm -v /opt/bitnami/postgresql/share/extension/.emptyfile \
    && mkdir -p /var/lib/apt/lists/partial \
    && apt-get update \
    && apt-get -y install \
            \
            build-essential \
            libssl-dev \
            git \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            cmake \
            wget \
    && mkdir -p /build/ \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \
    \
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TS_VERSION} \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker-bitnami" \
    && cd build && make install \
    && cd ~ \
    \
    && apt-get autoremove --purge -y \
            \
            build-essential \
            libssl-dev \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            cmake \
    && apt-get clean -y \
    && rm -rf \
        /build \
        "${HOME}/.cache" \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/*
        
# Adding pg_cron 
ARG PG_CRON_VERSION

RUN set -e \
    && cd /tmp\
    && apt-get update \
    && apt-get install -y  \
    ca-certificates \
    openssl \
    tar \
    autoconf \
    automake \
    g++ \
    clang \
    llvm \
    libtool \   
    libxml2-dev \
    make \
    perl \
    wget \
    && wget -O pg_cron.tar.gz "https://github.com/citusdata/pg_cron/archive/refs/tags/$PG_CRON_VERSION.tar.gz" \
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
    && apt-get autoremove --purge -y \
            autoconf \
            automake \
            g++ \
            clang \
            llvm \
            make \
            perl \
            wget \
    && apt-get clean -y \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 

# Add PostGIS Extension
ARG POSTGIS_VERSION

RUN set -eux \
    && apt update \
    && apt install -y \
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
        make \
        libpcre3-dev \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/${POSTGIS_VERSION}.tar.gz" \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
# build PostGIS
    \
    && cd /usr/src/postgis \
    && ./autogen.sh \
    && ./configure \
        --with-pcredir="$(pcre-config --prefix)"  \
        --with-geosconfig="/usr/bin/geos-config" \
        CFLAGS="-idirafter'/opt/bitnami/postgresql/include'"  # # Prefer latest system headers over Bitnami outdated libraries \
    && make -j$(nproc) \
    && make install \
    && cd / \
# clean
    && apt-get autoremove --purge -y \
        wget \
        g++\
        gcc \
        make \
    && apt-get clean -y \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 

# add Citus
ARG CITUS_VERSION
RUN set -eux \
    && apt-get update \
    && apt-get install -y libc-dev make libssl-dev curl gcc liblz4-dev libzstd-dev clang libkrb5-dev libicu-dev libxslt1-dev libxml2-dev llvm-dev libcurl4-openssl-dev \
    && CITUS_DOWNLOAD_URL="https://github.com/citusdata/citus/archive/refs/tags/v${CITUS_VERSION}.tar.gz" \
    && curl -L -o /tmp/citus.tar.gz "${CITUS_DOWNLOAD_URL}" \
    && tar -C /tmp -xvf /tmp/citus.tar.gz \
    && addgroup --system postgres \
    && adduser --system --ingroup postgres --home /opt/bitnami/postgresql --no-create-home postgres \
    && chown -R postgres:postgres /tmp/citus-${CITUS_VERSION} \
    && cd /tmp/citus-${CITUS_VERSION} \
    && PATH="/opt/bitnami/postgresql/bin:$PATH" ./configure \
    && make \
    && make install \
    && cd ~ \
    && rm -rf /tmp/citus.tar.gz /tmp/citus-${CITUS_VERSION} \
    \
    && apt-get autoremove --purge -y \
            \
            build-essential \
            libssl-dev \
            gcc \
            libc-dev \
            make \
    && apt-get clean -y \
    && rm -rf \
        /build \
        "${HOME}/.cache" \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 

# Add pg_repack Extention
ARG PG_REPACK_VERSION

RUN apt-get update \
    && apt-get install -y  unzip \
        build-essential \
        liblz4-dev \
        zlib1g-dev \
        libssl-dev \
        wget \
# build pg_repack
    && wget  -O /tmp/pg_repack-${PG_REPACK_VERSION}.zip "https://api.pgxn.org/dist/pg_repack/${PG_REPACK_VERSION}/pg_repack-${PG_REPACK_VERSION}.zip" \
    && unzip  /tmp/pg_repack-${PG_REPACK_VERSION}.zip -d /tmp \
    && cd /tmp/pg_repack-${PG_REPACK_VERSION} \
    && make \
    && make install \
#clean
    && apt-get autoremove --purge -y \
        unzip \
        build-essential \
        liblz4-dev \
        libssl-dev \
        zlib1g-dev \
        wget \
    && apt-get clean -y \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 

# Adding pgautofailover
ARG PG_AUTO_FAILOVER_VERSION
RUN apt-get update \
    && apt-get install -y  unzip \
        build-essential \
        liblz4-dev \
        zlib1g-dev \
        libedit-dev \
        libssl-dev \
        libxslt1-dev \
        wget \
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
    && apt-get autoremove --purge -y \
        unzip \
        build-essential \
        liblz4-dev \
        libedit-dev \
        libssl-dev \
        wget \
    && apt-get clean -y \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* 

USER 1001

ENTRYPOINT [ "/opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/postgresql/run.sh" ]
