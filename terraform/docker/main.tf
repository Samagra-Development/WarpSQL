module "warpsql-volumes" {
  source = "./docker_volumes"
}

module "warpsql-containers" {
  source = "./docker_containers"
}
