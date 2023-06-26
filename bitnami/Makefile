NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg15
CITUS_VERSION="11.2.0"
POSTGIS_MAJOR=3
PG_MAJOR=15
POSTGIS_VERSION=3.3.2
POSTGIS_SHA256=2a6858d1df06de1c5f85a5b780773e92f6ba3a5dc09ac31120ac895242f5a77b
PG_REPACK_VERSION = 1.4.8
PG_AUTO_FAILOVER_VERSION = 2.0
POSTGRES_HLL_VERSION = 2.17
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)

TS_VERSION=main
PREV_TS_VERSION=$(shell wget --quiet -O - https://raw.githubusercontent.com/timescale/timescaledb/${TS_VERSION}/version.config | grep update_from_version | sed -e 's!update_from_version = !!')
PREV_TS_IMAGE="timescale/timescaledb:$(PREV_TS_VERSION)-pg$(PG_VER_NUMBER)-bitnami"
PREV_IMAGE=$(shell if docker pull $(PREV_TS_IMAGE) >/dev/null; then echo "$(PREV_TS_IMAGE)"; else echo "bitnami/postgresql:$(PG_VER_NUMBER)"; fi )

# Beta releases should not be tagged as latest, so BETA is used to track.
BETA=$(findstring rc,$(TS_VERSION))
TAG_VERSION=$(ORG)/$(NAME):$(TS_VERSION)-$(PG_VER)-bitnami
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)-bitnami
TAG=-t $(TAG_VERSION) $(if $(BETA),,-t $(TAG_LATEST))

DOCKER_BUILD_ARGS = --build-arg PG_VERSION=$(PG_VER_NUMBER) \
		    --build-arg TS_VERSION=$(TS_VERSION) \
		    --build-arg PREV_IMAGE=$(PREV_IMAGE) \
		    --build-arg CITUS_VERSION=$(CITUS_VERSION) \
		    --build-arg PG_REPACK_VERSION=$(PG_REPACK_VERSION) \
		    --build-arg PG_AUTO_FAILOVER_VERSION=$(PG_AUTO_FAILOVER_VERSION)  \
		    --build-arg POSTGIS_MAJOR=$(POSTGIS_MAJOR) \
		    --build-arg PG_MAJOR=$(PG_MAJOR) \
		    --build-arg POSTGIS_VERSION=$(POSTGIS_VERSION) \
	        --build-arg POSTGIS_SHA256=$(POSTGIS_SHA256)  \
		    --build-arg POSTGRES_HLL_VERSION=$(POSTGRES_HLL_VERSION)

default: image

.build_$(TS_VERSION)_$(PG_VER): Dockerfile
	test -n "$(TS_VERSION)"  # TS_VERSION
	test -n "$(PREV_TS_VERSION)"  # PREV_TS_VERSION
	docker build -f ./Dockerfile $(DOCKER_BUILD_ARGS) $(TAG)  ..
	touch .build_$(TS_VERSION)_$(PG_VER)-bitnami

build-docker-cache: Dockerfile
	docker buildx create --use --driver=docker-container
	docker buildx  build  -f ./Dockerfile --progress=plain --load --cache-to "type=gha,mode=max" --cache-from type=gha   $(DOCKER_BUILD_ARGS) $(TAG) ..
	touch .build_$(TS_VERSION)_$(PG_VER) 
image: .build_$(TS_VERSION)_$(PG_VER)

push: image
	docker push $(TAG_VERSION)
	if [ -z "$(BETA)" ]; then \
		docker push $(TAG_LATEST); \
	fi

clean:
	rm -f *~ .build_*

.PHONY: default image push clean build-docker-cache
