output "web_public_ips" { value = aws_instance.web[*].public_ip }
output "db_private_ip" { value = aws_instance.db.private_ip }
