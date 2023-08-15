terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_volume" "warpsql-postgres" {
  name = "warpsql-postgres"
}
resource "docker_volume" "warpsql-barman" {
  name = "warpsql-barman"
}

