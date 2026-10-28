variable "region" {
  default = "ap-south-1"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "key_name" {
  type = string
}
variable "web_count" {
  type    = number
  default = 2
}
variable "admin_cidr" {
  type = string
  validation {
    condition     = var.admin_cidr != "0.0.0.0/0"
    error_message = "SSH must not be open to the whole internet."
  }
}
