terraform {
  backend "s3" {
    bucket = "spm-lab-tfstate-kripansh-27009"
    key    = "exp2/terraform.tfstate"
    region = "ap-south-1"
  }
}
