NAME=postgres
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=samagragovernance
PG_VER=pg15
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
TS_VERSION=2.13.0
PG_CRON_VERSION=v1.6.0
POSTGIS_VERSION=3.4.2 
CITUS_VERSION=12.1.0
PG_REPACK_VERSION=1.5.0
PG_AUTO_FAILOVER_VERSION=2.1
POSTGRES_HLL_VERSION=2.18
PG_JOBMON_VERSION=1.4.1
PG_PARTMAN_VERSION=5.0.1
PREV_TS_VERSION=$(shell wget --quiet -O - https://raw.githubusercontent.com/timescale/timescaledb/${TS_VERSION}/version.config | grep update_from_version | sed -e 's!update_from_version = !!')
PREV_TS_IMAGE="timescale/timescaledb:$(PREV_TS_VERSION)-pg$(PG_VER_NUMBER)$(PREV_EXTRA)"
PREV_IMAGE=$(shell if docker pull $(PREV_TS_IMAGE) >/dev/null; then echo "$(PREV_TS_IMAGE)"; else echo "postgres:$(PG_VER_NUMBER)-alpine"; fi )
PLATFORM=linux/amd64,linux/arm64
# Retrieve the latest Git tag for the current commit
RELEASE_TAG = $(shell git describe --tags --abbrev=0 --exact-match HEAD 2>/dev/null)

WARPSQL_VERSION := $(if $(RELEASE_TAG),$(RELEASE_TAG),dev-$(shell git rev-parse HEAD))

# Pre releases should not be tagged as latest, so PRE_RELEASE is used to track.
PRE_RELEASE=$(shell echo "$(WARPSQL_VERSION)" | grep -Eo "alpha|beta|rc")

# PUSH_MULTI can be set to nothing for dry-run without pushing during multi-arch build
PUSH_MULTI=--push
TAG_VERSION=$(ORG)/$(NAME):$(WARPSQL_VERSION)-pg$(PG_VER_NUMBER)
TAG_LATEST=$(ORG)/$(NAME):latest-pg$(PG_VER_NUMBER)
TAG=-t $(TAG_VERSION) $(if $(PRE_RELEASE),,-t $(TAG_LATEST))
TAG_OSS=-t $(TAG_VERSION)-oss $(if $(PRE_RELEASE),,-t $(TAG_LATEST)-oss)

DOCKER_BUILD_ARGS = --build-arg TS_VERSION=$(TS_VERSION) \
					--build-arg PG_VERSION=$(PG_VER_NUMBER) \
					--build-arg PREV_IMAGE=$(PREV_IMAGE) \
					--build-arg PG_CRON_VERSION=$(PG_CRON_VERSION) \
					--build-arg PG_REPACK_VERSION=$(PG_REPACK_VERSION)\
					--build-arg POSTGIS_VERSION=$(POSTGIS_VERSION) \
					--build-arg CITUS_VERSION=$(CITUS_VERSION) \
					--build-arg PG_AUTO_FAILOVER_VERSION=$(PG_AUTO_FAILOVER_VERSION)  \
					--build-arg POSTGRES_HLL_VERSION=$(POSTGRES_HLL_VERSION)\
					--build-arg PG_JOBMON_VERSION=$(PG_JOBMON_VERSION) \
					--build-arg PG_PARTMAN_VERSION=$(PG_PARTMAN_VERSION)



default: image

.multi_$(WARPSQL_VERSION)_$(PG_VER)_oss: Dockerfile
	docker buildx create --platform $(PLATFORM) --name multibuild --use
	docker buildx inspect multibuild --bootstrap
	docker buildx build --platform $(PLATFORM) \
		--build-arg OSS_ONLY=" -DAPACHE_ONLY=1" \
		$(DOCKER_BUILD_ARGS) \
		$(TAG_OSS) $(PUSH_MULTI) .
	touch .multi_$(WARPSQL_VERSION)_$(PG_VER)_oss
	docker buildx rm multibuild

.multi_$(WARPSQL_VERSION)_$(PG_VER): Dockerfile
	docker buildx create --platform $(PLATFORM) --name multibuild --use
	docker buildx inspect multibuild --bootstrap
	docker buildx build --platform $(PLATFORM) \
		$(DOCKER_BUILD_ARGS) \
		$(TAG) $(PUSH_MULTI) .
	touch .multi_$(WARPSQL_VERSION)_$(PG_VER)
	docker buildx rm multibuild

.build_$(WARPSQL_VERSION)_$(PG_VER)_oss: Dockerfile
	docker build --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" \
		$(DOCKER_BUILD_ARGS) \
		$(TAG_OSS) .
	touch .build_$(WARPSQL_VERSION)_$(PG_VER)_oss

.build_$(WARPSQL_VERSION)_$(PG_VER): Dockerfile
	docker build \
		$(DOCKER_BUILD_ARGS) \
		$(TAG) .
	touch .build_$(WARPSQL_VERSION)_$(PG_VER)

image: .build_$(WARPSQL_VERSION)_$(PG_VER)

image-oss: .build_$(WARPSQL_VERSION)_$(PG_VER)_oss

push: image
	docker push $(TAG_VERSION)
	if [ -z "$(PRE_RELEASE)" ]; then \
		docker push $(TAG_LATEST); \
	fi

push-oss: image-oss
	docker push $(TAG_VERSION)-oss
	if [ -z "$(PRE_RELEASE)" ]; then \
		docker push $(TAG_LATEST)-oss; \
	fi

multi: .multi_$(WARPSQL_VERSION)_$(PG_VER)

multi-oss: .multi_$(WARPSQL_VERSION)_$(PG_VER)_oss

all: multi multi-oss

clean:
	rm -f *~ .build_* .multi_*
	-docker buildx rm multibuild

.PHONY: default image push push-oss image-oss multi multi-oss clean all
