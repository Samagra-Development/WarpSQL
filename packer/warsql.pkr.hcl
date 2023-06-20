packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "image_repository" {
  type    = string
  default = "samagragovernance/postgres"
}

source "docker" "alpine" {
  image  = "postgres:15-alpine"
  commit = true
  changes = [
    "ENTRYPOINT [\"docker-entrypoint.sh\"]",
    "CMD [\"postgres\"]"
  ]
  run_command = ["-d", "-i", "-u=root", "-t", "--entrypoint=/bin/sh", "--", "{{.Image}}"]
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

build {
  name = "warpsql"
  sources = [
    "source.docker.alpine",
    "source.docker.bitnami"
  ]
  provisioner "shell" {
    environment_vars = [
      "EXTENSIONS=timescaledb,pgvector,postgis,zombodb,pg_repack,pgautofailover,hll,citus",
      "PG_VERSION=15",
      "PG_VER=pg15",
      "CITUS_VERSION=11.2.0",
      "POSTGIS_VERSION=3.3.2",
      "PG_REPACK_VERSION=1.4.8",
      "PG_AUTO_FAILOVER_VERSION=2.0",
      "POSTGRES_HLL_VERSION=2.17",
      "POSTGIS_SHA256=2a6858d1df06de1c5f85a5b780773e92f6ba3a5dc09ac31120ac895242f5a77b",
      "TS_VERSION=main"
    ]
    script = "postgres-alpine.sh"
    only   = ["source.docker.alpine"]
  }

  provisioner "file" {
    source      = "timescaledb-bitnami-entrypoint.sh"
    destination = "/opt/bitnami/scripts/postgresql/timescaledb-bitnami-entrypoint.sh"
    only        = ["source.docker.bitnami"]

  }

  provisioner "shell" {
    environment_vars = [
      "EXTENSIONS=timescaledb,pgvector,postgis,zombodb,pg_repack,pgautofailover,hll,citus",
      "PG_VERSION=15",
      "PG_VER=pg15",
      "CITUS_VERSION=11.2.0",
      "POSTGIS_VERSION=3.3.3+dfsg-1~exp1.pgdg110+1",
      "PG_REPACK_VERSION=1.4.8",
      "POSTGIS_MAJOR=3",
      "PG_MAJOR=15",
      "PG_AUTO_FAILOVER_VERSION=2.0",
      "POSTGRES_HLL_VERSION=2.17",
      "POSTGIS_SHA256=2a6858d1df06de1c5f85a5b780773e92f6ba3a5dc09ac31120ac895242f5a77b",
      "TS_VERSION=main"
    ]
    script = "postgres-bitnami.sh"
    only   = ["source.docker.bitnami"]
  }

  post-processor "docker-tag" {
    repository = var.image_repository
    tags       = ["pg15-${source.name}", "latest"]
  }

}
