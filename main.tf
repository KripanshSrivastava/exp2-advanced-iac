terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "network" {
  source              = "./modules/network"
  name                = "spm"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  az                  = "${var.region}a"
  admin_cidr          = var.admin_cidr
}

module "compute" {
  source            = "./modules/compute"
  web_count         = var.web_count
  instance_type     = var.instance_type
  key_name          = var.key_name
  db_private_ip     = "10.0.2.15"
  public_subnet_id  = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id
  web_sg_id         = module.network.web_sg_id
  db_sg_id          = module.network.db_sg_id
}
