
# 1. create a VPC  
# 2. Create Internet Gateway 
# 3. Create Custom Route Table 
# 4. Create a Subnet  
# 5. Associate subnet with Route Table 
# 6. Create Security Group to allow port 22,80,443 or all ports , traffic  
# 7. Create a network interface with an ip in the subnet that was created in step 4  
#8. Assign an elastic IP to the network interface created in step 7 
#9. Create ec2  server 

provider "aws" {
  region = "us-east-1"
}

# 1. create a VPC  

resource "aws_vpc" "prod_vpc" {
  cidr_block       = "10.81.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "prod_vpc"
  }
}

#Create Internet Gateway

resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "prod_igw"
  }
}

# 3. Create Custom Route Table

resource "aws_route_table" "prod_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/24"
    gateway_id = aws_internet_gateway.prod_igw.id
  }

  tags = {
    Name = "prod_rt"
  }
}

#4. Create a Subnet 

resource "aws_subnet" "prod_sn" {
  vpc_id     = aws_vpc.prod_vpc.id
  cidr_block = "10.81.1.0/24"

  tags = {
    Name = "prod_sn"
  }
}

#Associate subnet with Route Table 

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod_sn.id
  route_table_id = aws_route_table.prod_rt.id
}

#Create Security Group to allow port 22,80,443 or all ports , all traffic 

resource "aws_security_group" "prod_sg" {
  name        = "allow_prod"
  description = "Allow prod inbound traffic"
  //vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "allow 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "allow 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "allow 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "prod_sg"
  }
}

#Create a network interface with an ip in the subnet that was created in step 4  

resource "aws_network_interface" "prod_nic" {
  subnet_id   = aws_subnet.prod_sn.id
  private_ips = ["10.81.1.22"]
  //security_groups = [aws_security_group.prod_sg.id]

  tags = {
    Name = "prod_nic"
  }

}

#Assign an elastic IP to the network interface created in step 

#   resource "aws_eip" "prod_eip" {
#    vpc                       = true
#    network_interface         = aws_network_interface.prod_nic.id
#    associate_with_private_ip = "10.81.1.22"
#    depends_on                = [aws_internet_gateway.prod_igw]
#  }

#   output "server_public_ip" {
#    value = aws_eip.prod_eip.public_ip
#  }

#Create ec2  server 

resource "aws_instance" "Prod-server" {
  #  ami               = "ami-09d3b3274b6c5d4aa"
  ami             = "ami-005f9685cb30f234b"
  instance_type   = "t2.micro"
  key_name        = "AutomationECR"
  security_groups = [aws_security_group.prod_sg.id]
  user_data       = <<EOF
        #!/bin/bash
        sudo apt update 
        sudo apt install nginx -y
        sudo apt install git -y
        EOF

  tags = {
    Name = "Prod-server"
  }

  #  network_interface {
  #    device_index         = 0
  #    network_interface_id = aws_network_interface.prod_nic.id
  #  }
  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo yum update", 
  #     "sudo yum install git -y"
  #    ]

  #   }
}
