#
#variable "region" {}
variable "access_key" {}
variable "secret_key" {}
#
provider "aws" {
    region = var.aws_region
    access_key = var.access_key
    secret_key = var.secret_key
}

resource "aws_security_group" "web_sg" {
    name        = "Web-Server-Security-Group"
    description = "Allow TLS 80, 443 Security Group"

    ingress {
        description      = "http"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        description      = "http"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "Web-Server-Security-Group"
    }
}

resource "aws_launch_configuration" "web-lc" {
    name          = "Web-Server-HA-LC-config"
    image_id      = data.aws_ami.latest_ubuntu_20_x86-64.id
    instance_type = var.instance_type
    security_groups = [aws_security_group.web_sg.id]
    user_data = file("./scripts/user_data.tpl")

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "web_asg" {
    name                      = "Web-Server-HA-ASG"
    launch_configuration = aws_launch_configuration.web-lc.name
    max_size                  = 2
    min_size                  = 2
    min_elb_capacity          = 2
    vpc_zone_identifier       = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]
    health_check_type         = "ELB"
    load_balancers            = [aws_elb.web_elb.name]
    health_check_grace_period = 300

    tag {
        key                 = "Name"
        value               = "Web-Server-HA"
        propagate_at_launch = true
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_elb" "web_elb" {
    name               = "Web-Server-ELB"
    availability_zones = [data.aws_availability_zones.available.names[0],data.aws_availability_zones.available.names[1]]
    security_groups = [aws_security_group.web_sg.id]
    listener {
        instance_port      = 80
        instance_protocol  = "http"
        lb_port            = 80
        lb_protocol        = "http"
    }

    health_check {
        healthy_threshold  = 2
        interval           = 10
        target             = "HTTP:80/"
        timeout            = 3
        unhealthy_threshold = 2
    }

    tags = {
        Name = "Web-Server-ELB"
    }
}

resource "aws_default_subnet" "default_az1" {
    availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
    availability_zone = data.aws_availability_zones.available.names[1]
}