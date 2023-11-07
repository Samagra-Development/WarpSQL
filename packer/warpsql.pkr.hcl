# Packer configuration file for building a PostgreSQL image with multiple sources and provisioners
packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}
# # This variable defines the repository where the built image will be committed.
variable "image_repository" {
  type    = string
  default = "warpsql"
}
# Tags to be applied to the built image
variable "image_tags" {
  type    = list(string)
  default = ["latest"]

}
variable "extentions" {
    type = string
    default = "timescaledb,pgvector,postgis,zombodb,pg_repack,pgautofailover,hll,citus,pg_cron"
}
source "docker" "alpine" {
  image  = "postgres:15-alpine"
  commit = true
  # Restore the parent image's ENTRYPOINT and CMD instructions
  changes = [
    "ENTRYPOINT [\"docker-entrypoint.sh\"]",
    "CMD [\"postgres\"]"
  ]
  run_command = ["-d", "-i", "-u=root", "-t", "--entrypoint=/bin/sh", "--", "{{.Image}}"] # running as the root user regardless of user instruction
}

source "docker" "bitnami" {
  image  = "bitnami/postgresql:15"
  commit = true
  changes = [
    "USER 1001",
    "ENTRYPOINT [ \"/opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh\" ]",
    "CMD [ \"/opt/bitnami/scripts/postgresql/run.sh\" ]"
  ]
  run_command = ["-d", "-i", "-u=root", "-t", "--entrypoint=/bin/sh", "--", "{{.Image}}"]
}

# Build configuration
build {
  name = "warpsql"
  # Specify the sources for the build
  sources = [
    "source.docker.alpine",
    "source.docker.bitnami"
  ]
  # provisioners for the Alpine image
  provisioner "shell" {
    environment_vars = [
      "EXTENSIONS=${var.extentions}",
      "PG_VERSION=15",
      "PG_VER=pg15",
      "CITUS_VERSION=11.2.0",
      "POSTGIS_VERSION=3.3.2",
      "PG_REPACK_VERSION=1.4.8",
      "PG_AUTO_FAILOVER_VERSION=2.0",
      "POSTGRES_HLL_VERSION=2.17",
      "POSTGIS_SHA256=2a6858d1df06de1c5f85a5b780773e92f6ba3a5dc09ac31120ac895242f5a77b",
      "PG_CRON_VERSION=v1.6.0",
      "TS_VERSION=main"
    ]
    script = "postgres-alpine.sh"
    only   = ["docker.alpine"]
  }

  # provisioners for the Bitnami image
  provisioner "file" {
    source      = "timescaledb-bitnami-entrypoint.sh"
    destination = "/opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh"
    only        = ["docker.bitnami"]

  }

  provisioner "shell" {
    environment_vars = [
      "EXTENSIONS=${var.extentions}",
      "PG_VERSION=15",
      "PG_VER=pg15",
      "CITUS_VERSION=11.2.0",
      "POSTGIS_VERSION=3.3.2",
      "PG_REPACK_VERSION=1.4.8",
      "PG_MAJOR=15",
      "PG_AUTO_FAILOVER_VERSION=2.0",
      "POSTGRES_HLL_VERSION=2.17",
      "POSTGIS_SHA256=2a6858d1df06de1c5f85a5b780773e92f6ba3a5dc09ac31120ac895242f5a77b",
      "PG_CRON_VERSION=v1.6.0",
      "TS_VERSION=main"
    ]
    script = "postgres-bitnami.sh"
    only   = ["docker.bitnami"]
  }

  post-processor "docker-tag" {
    repository = var.image_repository
    tags       = var.image_tags
  }

}
