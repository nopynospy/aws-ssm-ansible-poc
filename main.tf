terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = var.region_id
  access_key = var.access_key
  secret_key = var.secret_key
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "example"
  cidr                 = var.vpc_cidr
  azs                  = ["${var.region_id}a"]
  private_subnets      = [var.private_subnet_cidr]
  public_subnets       = [var.public_subnet_cidr]
  enable_dns_hostnames = true
}

module "latest_aws_linux_2_ami" {
  source = "git::https://github.com/nopynospy/terraform_aws_linux2_ami.git"
}

resource "aws_security_group" "public" {
  name        = "public-instance-sg"
  description = "Test SSM"
  vpc_id      = module.vpc.vpc_id
  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module ssm_iam {
  source = "./modules/ssm_iam_attachment"
}

module "aws_linux_2_patch" {
  source              = "./modules/aws_linux_2_patch"
  patch_baseline_name = "aws_linux_2_patch_baseline"
  patch_group_name    = "aws_linux_2_patch_group"
}

resource "aws_instance" "public" {
  instance_type = var.instance_type
  associate_public_ip_address = true
  ami           = module.latest_aws_linux_2_ami.aws_linux_2_id
  iam_instance_profile = module.ssm_iam.ssm_iam_profile_name
  vpc_security_group_ids = [aws_security_group.public.id]
  subnet_id            = module.vpc.public_subnets[0]
  tags = {
    Name          = "Test-public"
    "Patch Group" = module.aws_linux_2_patch.patch_group_id
    "SSM" = "Ansible"
  }
}

resource "aws_s3_bucket" "this" {
  bucket = var.ansible_output_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    id = "log"

    expiration {
      days = 60
    }

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

output "bucket" {
  description = "Use this as --output-s3-bucket-name in 'aws ssm send-command' and destination of 'aws s3 cp'"
  value = aws_s3_bucket.this.bucket
}