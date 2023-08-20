terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.42.0"
    }
  }
  required_version = ">= 0.14.5"
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "sg_22_80" {
  name_prefix = "warpsql"
  vpc_id      = aws_vpc.vpc.id
  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # postgres access
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "warpsql-rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "deployer" {
  key_name_prefix = "warpsql"
  public_key      = tls_private_key.warpsql-rsa.public_key_openssh
}
resource "local_sensitive_file" "pem_file" {
  # write the private key to local for ssh access
  filename        = pathexpand("./${aws_key_pair.deployer.key_name}.pem")
  file_permission = "600"
  content         = tls_private_key.warpsql-rsa.private_key_pem
}

resource "aws_instance" "warpsql" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_22_80.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  root_block_device {
    volume_size = "16"
  }
  tags = {
    Name = "WarpSQL"
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    # password = var.root_password
    private_key = tls_private_key.warpsql-rsa.private_key_pem
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "echo Hi"
    ]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --become-method sudo --private-key '${local_sensitive_file.pem_file.filename}'  playbook-warpsql.yml"
  }



}

resource "aws_instance" "barman" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_22_80.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  user_data                   = <<EOF
  #cloud-config
    hostname: barman
  EOF
  root_block_device {
    volume_size = "16"
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    # password = var.root_password
    private_key = tls_private_key.warpsql-rsa.private_key_pem
    host        = self.public_ip
  }
  tags = {
    Name = "Barman"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Hi"
    ]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --become-method sudo --private-key '${local_sensitive_file.pem_file.filename}'  playbook-barman.yml --extra-vars 'warpsql_ip=${aws_instance.warpsql.public_ip}' "
  }
}

output "public_ip" {
  value = [aws_instance.warpsql.public_ip, aws_instance.barman.public_ip]
}

# output "public_ip" {
#   value = aws_instance.warpsql.public_ip
# }