variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
  type        = string

}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.1.0.0/24"
  type        = string

}


variable "region" {
  description = "The region Terraform deploys your instance"
  default     = "us-east-1"
  type        = string

}

variable "warpsql_password" {
  description = "The password for Warpsql PostgreSQL connection"
  type        = string
  default     = "warpsql"
}
variable "warpsql_disk_size" {
  description = "Size of the WarpSQL instance disk"
  type        = string
  default     = "16"
}

variable "barman_disk_size" {
  description = "Size of the Barman instance disk"
  type        = string
  default     = "16"
}

variable "ansible_disk_size" {
  description = "Size of the Ansible instance disk"
  type        = string
  default     = "8"
}

variable "img_warpsql" {
  description = "Docker image for App 1"
  type        = string
}

variable "img_barman" {
  description = "Docker image for barman"
  type        = string
}