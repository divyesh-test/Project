provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
  
}

resource "aws_subnet" "my_private_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
  
}

resource "aws_subnet" "my_public_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.2.0/24"
  
}

resource "aws_route_table" "my_route_table" {
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table_association" "my_route_table_association" {
    subnet_id = aws_subnet.my_public_subnet.id
    route_table_id = aws_route_table.my_route_table.id
}

resource "aws_internet_gateway" "my_internet_gateway" {
    vpc_id = aws_vpc.my_vpc.id   

}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_internet_gateway.id
}


resource "aws_security_group" "my_security_group" {
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "my_security_ingress" {
    security_group_id = aws_security_group.my_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "my_security_ingress_for_5678" {
    security_group_id = aws_security_group.my_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 5678
    to_port = 5678
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "my_security_egress" {
    security_group_id = aws_security_group.my_security_group.id
    #from_port = 0
   # to_port = 0
    ip_protocol = "-1"
    cidr_ipv4 = "0.0.0.0/0"
  
}

resource "tls_private_key" "private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
  
}

resource "aws_key_pair" "my_key_pair" {
    key_name = "key-local"
    public_key = tls_private_key.private_key.public_key_openssh
  
}

output "my_private_key" {
    value = tls_private_key.private_key.private_key_pem
    sensitive = true
  
}


resource "aws_instance" "my_ec2" {
    ami = "ami-0af9569868786b23a"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    count = 2
    subnet_id = aws_subnet.my_public_subnet.id
    vpc_security_group_ids = [ aws_security_group.my_security_group.id ]
    key_name = aws_key_pair.my_key_pair.key_name


    user_data = <<-EOF
            #!/bin/bash
            yum update -y
            yum install -y git python3
	        yum install -y python3-pip
            git clone https://github.com/divyesh-test/Project.git
            cd /home/ec2-user/Projects
            cd app/
	        pip install -r requirements.txt
            FLASK_APP=app.py nohup python3 app.py > output.log 2>&1 &
            EOF

}

output "public_ipv4_address" {
    value = [for instance in aws_instance.my_ec2 : instance.public_ip]
  
}
