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

locals {
  ami_id = "ami-053b0d53c279acc90" #ubuntu 22.04 LTS
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
    from_port   = 7000
    to_port     = 7000
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
  ami                         = local.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_22_80.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  root_block_device {
    volume_size = var.warpsql_disk_size
  }
  user_data = <<EOF
  #cloud-config
    hostname: barman
  EOF

  tags = {
    Name = "WarpSQL"
  }
}

resource "aws_instance" "barman" {
  ami                         = local.ami_id
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
    volume_size = var.barman_disk_size
  }
  tags = {
    Name = "Barman"
  }
}


resource "aws_instance" "ansible" {
  ami                         = local.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_22_80.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  user_data                   = <<EOF
  #cloud-config
    hostname: ansible
  EOF
  root_block_device {
    volume_size = var.ansible_disk_size
  }
  tags = {
    Name = "ansible"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.warpsql-rsa.private_key_pem
    host        = self.public_ip
  }
  # install and setup ansible
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install python3-pip python3.10-venv ",
      "python3 -m pip install --user pipx",
      "python3 -m pipx ensurepath",
      "python3 -m pipx install --include-deps ansible",
      "mkdir -p ~/warpsql/ssh",
      "mkdir -p /tmp/warpsql"
    ]
  }


}

resource "null_resource" "warpsql" {
  depends_on = [aws_instance.ansible, aws_instance.warpsql, aws_instance.barman]

  triggers = {
    always_run = "${timestamp()}" # always run the ansible script
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.warpsql-rsa.private_key_pem
    host        = aws_instance.ansible.public_ip
  }

  # save required files on ansible host
  provisioner "file" {
    content     = <<EOF
barman:
  hosts:
    br1:
      ansible_host: ${aws_instance.barman.private_ip}

warpsql:
  hosts:
    wsql1:
      ansible_host: ${aws_instance.warpsql.private_ip}

EOF
    destination = "/tmp/warpsql/inventory.yml"
  }

  provisioner "file" {
    source      = "config"
    destination = "/tmp/warpsql/"
  }
  provisioner "file" {
    source      = local_sensitive_file.pem_file.filename
    destination = "/tmp/warpsql/warpsql-ansible.pem"
  }

  provisioner "file" {
    source      = "playbook-warpsql.yml"
    destination = "/tmp/warpsql/playbook-warpsql.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "cp -r /tmp/warpsql/* /home/ubuntu/warpsql",
      "cd ~/warpsql",
      "chmod 700 ~/warpsql/warpsql-ansible.pem",
    "ANSIBLE_HOST_KEY_CHECKING=False /home/ubuntu/.local/bin/ansible-playbook -u ubuntu -i inventory.yml --become-method sudo --private-key 'warpsql-ansible.pem'  playbook-warpsql.yml --extra-vars 'warpsql_password=${var.warpsql_password} img_warpsql=${var.img_warpsql} img_barman=${var.img_barman}'"]
  }
}

output "public_ip" {
  value = {
    WarpSQL = aws_instance.warpsql.public_ip
    Barman  = aws_instance.barman.public_ip
  Ansible = aws_instance.ansible.public_ip }
}

