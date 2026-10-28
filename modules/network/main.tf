resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name}-vpc", Experiment = "02", ManagedBy = "Terraform" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block=var.public_subnet_cidr
  availability_zone = var.az
  tags              = { Name = "${var.name}-public", Tier = "web" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.az
  tags              = { Name = "${var.name}-private", Tier = "db" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Web tier: HTTP from the internet, SSH from the administrator only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from the administrator address only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # A public web server must accept HTTP from anywhere; documented exception.
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Outbound for package installation"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.name}-web-sg" }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Database tier: MySQL port from the web tier only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from the web security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Replies and traffic inside the VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = { Name = "${var.name}-db-sg" }
}
