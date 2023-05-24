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
ARG CITUS_VERSION

LABEL maintainer="Timescale https://www.timescale.com"

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/
COPY --from=oldversions /opt/bitnami/postgresql/lib/.emptyfile /opt/bitnami/postgresql/lib/timescaledb-*.so /opt/bitnami/postgresql/lib/
COPY --from=oldversions /opt/bitnami/postgresql/share/extension/.emptyfile /opt/bitnami/postgresql/share/extension/timescaledb--*.sql /opt/bitnami/postgresql/share/extension/
COPY bitnami/timescaledb-bitnami-entrypoint.sh /opt/bitnami/scripts/postgresql/

USER 0
ARG TS_VERSION
# RUN set -ex \
#     && rm -v /opt/bitnami/postgresql/lib/.emptyfile \
#     && rm -v /opt/bitnami/postgresql/share/extension/.emptyfile \
#     && mkdir -p /var/lib/apt/lists/partial \
#     && apt-get update \
#     && apt-get -y install \
#             \
#             build-essential \
#             libssl-dev \
#             git \
#             \
#             dpkg-dev \
#             gcc \
#             libc-dev \
#             make \
#             cmake \
#             wget \
#     && mkdir -p /build/ \
#     && git clone https://github.com/timescale/timescaledb /build/timescaledb \
#     \
#     # Build current version \
#     && cd /build/timescaledb && rm -fr build \
#     && git checkout ${TS_VERSION} \
#     && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker-bitnami" \
#     && cd build && make install \
#     && cd ~ \
#     \
#     # Install Citus
#     && apt-get update \
#     && apt-get install -y curl liblz4-dev libzstd-dev clang libkrb5-dev libicu-dev libxslt1-dev libxml2-dev llvm-dev libcurl4-openssl-dev \
#     && CITUS_DOWNLOAD_URL="https://github.com/citusdata/citus/archive/refs/tags/v${CITUS_VERSION}.tar.gz" \
#     && curl -L -o /tmp/citus.tar.gz "${CITUS_DOWNLOAD_URL}" \
#     && tar -C /tmp -xvf /tmp/citus.tar.gz \
#     && addgroup --system postgres \
#     && adduser --system --ingroup postgres --home /opt/bitnami/postgresql --no-create-home postgres \
#     && chown -R postgres:postgres /tmp/citus-${CITUS_VERSION} \
#     && cd /tmp/citus-${CITUS_VERSION} \
#     && PATH="/opt/bitnami/postgresql/bin:$PATH" ./configure \
#     && make \
#     && make install \
#     && cd ~ \
#     && rm -rf /tmp/citus.tar.gz /tmp/citus-${CITUS_VERSION} \
#     \
#     && apt-get autoremove --purge -y \
#             \
#             build-essential \
#             libssl-dev \
#             \
#             dpkg-dev \
#             gcc \
#             libc-dev \
#             make \
#             cmake \
#     && apt-get clean -y \
#     && rm -rf \
#         /build \
#         "${HOME}/.cache" \
#         /var/lib/apt/lists/* \
#         /tmp/*               \
#         /var/tmp/* \
#     \
#     # Update shared_preload_libraries
#     && sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'citus,timescaledb'/g" /opt/bitnami/postgresql/conf/postgresql.conf
    
# # Add PostGIS Extension
# ARG POSTGIS_MAJOR
# ARG PG_MAJOR
# ARG POSTGIS_VERSION

# RUN apt-get update \
#      && apt-get install -y lsb-release gnupg2 \
#      && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list \
#      && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
#      && apt-get update \
#       && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
#       && apt-get install -y --no-install-recommends \
#            ca-certificates \
#            \
#            postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
#            postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
#       && rm -rf /var/lib/apt/lists/*


RUN apt-get update -y -qq --fix-missing
RUN apt-get install -y wget gnupg

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main 15" >> /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt update
RUN apt-get update -y --fix-missing

RUN apt-get install -y git
RUN apt-get install -y curl
RUN apt-get install -y clang llvm gcc make build-essential libz-dev zlib1g-dev strace libssl-dev pkg-config

RUN apt-get install lsb-release wget software-properties-common gnupg -y

# Try to install the dependencies one by one
RUN wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 14

# RUN apt-get install -y postgresql-15 postgresql-server-dev-15

## b/c why not! http://www.inanzzz.com/index.php/post/3zs5/installing-ruby-on-debian-8
RUN apt-get install -y libreadline-dev libgdbm-dev openssl
RUN mkdir ruby && \
	cd ruby && \
	wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.0.tar.gz && \
	tar xvfz ruby-2.3.0.tar.gz && \
	cd ruby-2.3.0 && \
	./configure && \
	make -j64 && \
	make install
RUN gem install --no-document fpm


RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH="/home/.cargo/bin:${PATH}"
RUN cargo install cargo-pgrx
RUN cargo pgrx init \
	--pg15=/usr/lib/postgresql/15/bin/pg_config

USER 1001

ENTRYPOINT [ "/opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/postgresql/run.sh" ]
