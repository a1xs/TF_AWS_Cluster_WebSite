output "latest_ubuntu_20_x86-64_id" {
    description = "AMI ID"
    value = data.aws_ami.latest_ubuntu_20_x86-64.id
}

output "loadbalancer" {
    description = "DNS"
    value = aws_elb.web_elb.dns_name
}