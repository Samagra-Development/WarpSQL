NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg15
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
PG_CRON_VERSION=v1.6.0
PG_AUTO_FAILOVER_VERSION=2.1
TS_VERSION=2.13.0
POSTGIS_VERSION=3.4.2 	
CITUS_VERSION=12.1.0
PG_REPACK_VERSION=1.5.0
POSTGRES_HLL_VERSION=2.18
PREV_TS_VERSION=$(shell wget --quiet -O - https://raw.githubusercontent.com/timescale/timescaledb/${TS_VERSION}/version.config | grep update_from_version | sed -e 's!update_from_version = !!')
PREV_TS_IMAGE="timescale/timescaledb:$(PREV_TS_VERSION)-pg$(PG_VER_NUMBER)-bitnami"
PREV_IMAGE=$(shell if docker pull $(PREV_TS_IMAGE) >/dev/null; then echo "$(PREV_TS_IMAGE)"; else echo "bitnami/postgresql:$(PG_VER_NUMBER)"; fi )

# Retrieve the latest Git tag for the current commit
RELEASE_TAG = $(shell git describe --tags --abbrev=0 --exact-match HEAD 2>/dev/null)

WARPSQL_VERSION := $(if $(RELEASE_TAG),$(RELEASE_TAG),dev-$(shell git rev-parse HEAD))

# Pre releases should not be tagged as latest, so PRE_RELEASE is used to track.
PRE_RELEASE=$(shell echo "$(WARPSQL_VERSION)" | grep -Eo "alpha|beta|rc")

TAG_VERSION=$(ORG)/$(NAME):$(WARPSQL_VERSION)-$(PG_VER)-bitnami
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)-bitnami
TAG=-t $(TAG_VERSION) $(if $(PRE_RELEASE),,-t $(TAG_LATEST))

DOCKER_BUILD_ARGS = --build-arg PG_VERSION=$(PG_VER_NUMBER) \
					--build-arg TS_VERSION=$(TS_VERSION)  \
					--build-arg PREV_IMAGE=$(PREV_IMAGE) \
					--build-arg PG_CRON_VERSION=$(PG_CRON_VERSION) \
					--build-arg PG_REPACK_VERSION=$(PG_REPACK_VERSION) \
					--build-arg POSTGIS_VERSION=$(POSTGIS_VERSION) \
					--build-arg POSTGRES_HLL_VERSION=$(POSTGRES_HLL_VERSION)\
					--build-arg CITUS_VERSION=$(CITUS_VERSION) \
					--build-arg PG_AUTO_FAILOVER_VERSION=$(PG_AUTO_FAILOVER_VERSION)

default: image

.build_$(WARPSQL_VERSION)_$(PG_VER): Dockerfile
	docker build -f ./Dockerfile \
		$(DOCKER_BUILD_ARGS) \
		$(TAG) ..
	touch .build_$(WARPSQL_VERSION)_$(PG_VER)-bitnami

image: .build_$(WARPSQL_VERSION)_$(PG_VER)

push: image
	docker push $(TAG_VERSION)
	if [ -z "$(PRE_RELEASE)" ]; then \
		docker push $(TAG_LATEST); \
	fi

clean:
	rm -f *~ .build_*

.PHONY: default image push clean
