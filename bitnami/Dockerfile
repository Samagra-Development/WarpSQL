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
    && gettextize \
    && ./autogen.sh \
    && ./configure \
        --with-pcredir="$(pcre-config --prefix)"  --with-geosconfig="/usr/bin/geos-config"\
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

# Install zombodb extension
ARG PG_MAJOR
ENV RUSTFLAGS="-C target-cpu=native target-cpu=native link-arg=-fuse-ld=lld"
RUN apt-get update -y -qq --fix-missing \
    && apt-get install -y wget gnupg \
    && echo "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-14 main" >> /etc/apt/sources.list \
    && echo "deb http://security.ubuntu.com/ubuntu bionic-security main" >> /etc/apt/sources.list \
    && wget --quiet -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32 \
    && apt update \
    && apt-get update -y --fix-missing \
    && apt-get install -y git curl clang-14 llvm-14 gcc make build-essential libz-dev zlib1g-dev  pkg-config libreadline-dev libgdbm-dev libssl1.0-dev \
    && wget https://www.openssl.org/source/openssl-1.0.2l.tar.gz \
    && tar -xzvf openssl-1.0.2l.tar.gz \
    && cd openssl-1.0.2l \
    && ./config \
    && make install \
    && ln -sf /usr/local/ssl/bin/openssl `which openssl` \
    && mkdir ruby  \
	&& cd ruby \
	&& wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.0.tar.gz \
	&& tar xvfz ruby-2.3.0.tar.gz \
	&& cd ruby-2.3.0 \
	&& ./configure  --with-openssl-dir=/usr/include/openssl-1.0 \
	&& make -j64 \
	&& make install \
    && gem install --no-document fpm \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && export PATH="/.cargo/bin:$PATH" \
    && export PGRX_HOME="/.pgrx/" \
    && mkdir -p $PGRX_HOME \
    && cargo install cargo-pgrx --version 0.9.3 \
    && cargo pgrx init --pg${PG_MAJOR}=/opt/bitnami/postgresql/bin/pg_config \
    && git clone --depth 1 --branch ${ZOMBODB_VERSION} https://github.com/zombodb/zombodb.git \
    && cd zombodb \
    && export PATH="/.cargo/bin:$PATH" && cargo pgrx install --release \
    && cd / \
    && apt-get autoremove --purge -y git curl clang-14  gcc make build-essential   wget  \
    && rm -rf .cargo .gem  openssl-1.0.2l .rustup openssl-1.0.2l.tar.gz

USER 1001

ENTRYPOINT [ "/opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/postgresql/run.sh" ]
