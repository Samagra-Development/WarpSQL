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

variable "environment_tag" {
  description = "Environment tag"
  default     = "Learn"
  type        = string

}

variable "region" {
  description = "The region Terraform deploys your instance"
  default     = "us-east-1"
  type        = string

}
variable "ami_id" {
  description = "The AMI id of warpsql"
  type        = string
}

