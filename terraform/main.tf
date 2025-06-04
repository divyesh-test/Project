provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "project_vpc" {
    cidr_block = "10.0.0.0/16"
  
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.project_vpc.id
    cidr_block = "10.0.1.0/24"
  
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.project_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1a"
}

resource "aws_subnet" "public_subnet2" {
    vpc_id = aws_vpc.project_vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-south-1c"
  
}

resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.project_vpc.id
}

resource "aws_route_table_association" "route_table_association" {
    subnet_id = [aws_subnet.public_subnet.id, aws_subnet.public_subnet2.id  ]
    route_table_id = aws_route_table.route_table.id
}

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.project_vpc.id   

}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}


resource "aws_security_group" "security_group" {
    vpc_id = aws_vpc.project_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "security_group_ingress2" {
    security_group_id = aws_security_group.security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "security_group_ingress1" {
    security_group_id = aws_security_group.security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 5678
    to_port = 5678
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "security_group_egress1" {
    security_group_id = aws_security_group.security_group.id
    #from_port = 0
   # to_port = 0
    ip_protocol = "-1"
    cidr_ipv4 = "0.0.0.0/0"
  
}

resource "aws_lb" "load_balancer" {
    name = "load-balancer-test"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.security_group.id]
    subnets = [
        aws_subnet.public_subnet.id,
        aws_subnet.public_subnet2.id ] 
  
}

resource "aws_lb_target_group" "alb_target_group" {
    name = "ec2-target-group"
    port = "5678"
    protocol = "HTTP"
    vpc_id = aws_vpc.project_vpc.id
}

resource "aws_lb_target_group_attachment" "alb_tg_attach" {
    
    for_each = {
      for i, ec2 in aws_instance.instances1 : "ec2-${i}" => ec2.id
    }
    
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    port = 5678
    target_id = each.value
  
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.load_balancer.arn
    port = 80
    protocol = "HTTP"
  
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb_target_group.arn
    }
}

resource "tls_private_key" "private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
  
}

resource "aws_key_pair" "key_pair" {
    key_name = "key-local"
    public_key = tls_private_key.private_key.public_key_openssh
  
}

output "my_private_key" {
    value = tls_private_key.private_key.private_key_pem
    sensitive = true
  
}


resource "aws_instance" "instances1" {
    ami = "ami-0af9569868786b23a"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    count = 2
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [ aws_security_group.security_group.id ]
    key_name = aws_key_pair.key_pair.key_name


    user_data = <<-EOF
            #!/bin/bash
            yum update -y
            yum install -y git python3 python3-pip
            git clone https://github.com/divyesh-test/Project.git
            chown -R ec2-user:ec2-user /home/ec2-user/Project
            cd /home/ec2-user/Project
            cd ./app/
            pip3 install -r requirements.txt
            FLASK_APP=app.py nohup python3 app.py > output.log 2>&1 &
            EOF

}

output "public_ipv4_address" {
    value = [for instance in aws_instance.instances1 : instance.public_ip]
  
}
