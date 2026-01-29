############################
# Default VPC (READ ONLY)
############################
data "aws_vpc" "default" {
  default = true
}

############################
# Default Subnets
############################
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

############################
# Ubuntu 22.04 AMI (us-east-2)
############################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# SSH Key Pair
############################
resource "aws_key_pair" "deployer" {
  key_name   = "terra-automate-key"
  public_key = file("${path.module}/terra-key.pub")
}

############################
# Security Group
############################
resource "aws_security_group" "allow_user_to_connect" {
  name   = "allow-tls"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysecurity"
  }
}

############################
# EC2 Instance (Ubuntu)
############################
resource "aws_instance" "testinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.allow_user_to_connect.id]

  tags = {
    Name = "Automate-Ubuntu"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
}

