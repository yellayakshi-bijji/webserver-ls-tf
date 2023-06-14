#storing the terraform state file in s3 bucket
terraform {
  backend "s3" {
    bucket = "chocolatekibalti"
    key    = "terraform-module/webserver-lamp/webserverls.tfstate"
    region = "us-east-1"
  }
}