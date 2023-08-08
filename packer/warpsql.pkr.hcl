# Packer configuration file for building a PostgreSQL image with multiple sources and provisioners
packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
    amazon = {
      version = ">= 1.2.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
variable "extensions" {
  type    = string
  default = "timescaledb,pgvector,postgis,zombodb,pg_repack,pgautofailover,hll,citus"
}

variable "ami_name" {
  type    = string
  default = "warpsql"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "alpine" {
  ami_name        = var.ami_name
  instance_type   = "t2.micro"
  region          = var.region
  skip_create_ami = false
  source_ami_filter {
    filters = {
      name                = "alpine-3.18.2-x86_64-bios-cloudinit-r0"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["538276064493"]
    most_recent = true
  }
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 15
    volume_type           = "gp2"
    delete_on_termination = true
  }
  ssh_username = "alpine"
}

# The repository where the built docker image will be committed.
variable "image_repository" {
  type    = string
  default = "warpsql"
}


# Tags to be applied to the built image
variable "image_tags" {
  type    = list(string)
  default = ["latest"]

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
    "source.docker.bitnami",
    "source.amazon-ebs.alpine"
  ]

  provisioner "file" {
    source      = "./aws-alpine-entrypoint.sh"
    destination = "/tmp/aws-alpine-entrypoint.sh"
    only        = ["amazon-ebs.alpine"]
  }

  provisioner "shell" {
    valid_exit_codes = ["0"]
    # preserve the existing environment variables
    inline = [
      "echo 'permit nopass keepenv :wheel' | doas  tee /etc/doas.d/wheel.conf",
      "doas apk add bash"
    ]
    only = ["amazon-ebs.alpine"]
  }

  provisioner "shell" {
    script          = "aws-alpine-postgres-install.sh" # install PostgreSQL on the image
    execute_command = "chmod +x {{.Path}};  {{ .Vars }} doas {{.Path}}"
    only            = ["amazon-ebs.alpine"]

  }

  provisioner "shell" {
    valid_exit_codes = []
    environment_vars = [
      "EXTENSIONS=${var.extensions}",
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
    script          = "postgres-alpine.sh" # install all the extensions 
    execute_command = "chmod +x {{.Path}};  {{ .Vars }} doas {{.Path}}"
    only            = ["amazon-ebs.alpine"]

  }

  # provisioners for the Alpine image
  provisioner "shell" {
    environment_vars = [
      "EXTENSIONS=${var.extensions}",
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
      "EXTENSIONS=${var.extensions}",
      "PG_VERSION=15",
      "PG_VER=pg15",
      "CITUS_VERSION=11.2.0",
      "POSTGIS_VERSION=3.3.2",
      "PG_REPACK_VERSION=1.4.8",
      "PG_MAJOR=15",
      "PG_AUTO_FAILOVER_VERSION=2.0",
      "POSTGRES_HLL_VERSION=2.17",
      "POSTGIS_SHA256=2a6858d1df06de1c5f85a5b780773e92f6ba3a5dc09ac31120ac895242f5a77b",
      "TS_VERSION=main"
    ]
    script = "postgres-bitnami.sh"
    only   = ["docker.bitnami"]
  }

  provisioner "shell" {
    valid_exit_codes = ["0"]
    inline = [
      "doas mv /tmp/aws-alpine-entrypoint.sh /",
      "doas chown root:wheel /aws-alpine-entrypoint.sh",
      "doas chmod +x /aws-alpine-entrypoint.sh"
    ]
    only = ["amazon-ebs.alpine"]
  }


  post-processor "docker-tag" {
    repository = var.image_repository
    tags       = var.image_tags
    only       = ["docker.bitnami", "docker.alpine"]

  }

  post-processor "manifest" {
    output     = "warpsql-ami.json"
    strip_path = true
  }

}
