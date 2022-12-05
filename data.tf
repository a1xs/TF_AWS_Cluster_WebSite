data "aws_availability_zones" "available" {
#  state = "available"
}

data "aws_ami" "latest_ubuntu_20_x86-64" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}