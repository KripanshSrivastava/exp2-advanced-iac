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

resource "aws_instance" "web" {
  count                       = var.web_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.web_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  metadata_options { http_tokens = "required" }
  root_block_device { encrypted = true }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "<h1>web-${count.index + 1}</h1>" > /var/www/html/index.nginx-debian.html
    systemctl enable --now nginx
  EOF

  tags = { Name = "web-${count.index + 1}", Tier = "web", Experiment = "02" }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  private_ip             = var.db_private_ip
  vpc_security_group_ids = [var.db_sg_id]
  key_name               = var.key_name

  metadata_options { http_tokens = "required" }
  root_block_device { encrypted = true }

  # Stand-in for MySQL: any listener on 3306 lets the security group be tested.
  user_data = <<-EOF
    #!/bin/bash
    setsid nohup python3 -m http.server 3306 --bind 0.0.0.0 >/dev/null 2>&1 &
  EOF

  tags = { Name = "db-1", Tier = "db", Experiment = "02" }
}
