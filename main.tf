terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.1"
    }
  }
}

#creating a vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc_ws"
  }
}

#creating an Internet Gateway
resource "aws_internet_gateway" "igw" {
  depends_on = [aws_vpc.vpc, ]
  vpc_id     = aws_vpc.vpc.id

  tags = {
    Name = "igw_ws"
  }
}

#creating a public subnet
resource "aws_subnet" "publicsubnet" {
  depends_on        = [aws_vpc.vpc, ]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.avail_zone

  tags = {
    Name = "publicsubnet_ws"
  }
}

#creating a public route table
resource "aws_route_table" "publicrt" {
  depends_on = [aws_vpc.vpc, aws_internet_gateway.igw, ]
  vpc_id     = aws_vpc.vpc.id

  tags = {
    Name = "publicrt_ws"
  }

}

#creating a public route
resource "aws_route" "publicroute" {
  depends_on             = [aws_internet_gateway.igw, aws_subnet.publicsubnet]
  route_table_id         = aws_route_table.publicrt.id
  destination_cidr_block = var.allowallcidr
  gateway_id             = aws_internet_gateway.igw.id
}

#associating public routetable with public subnet
resource "aws_route_table_association" "publicrtsassociation" {
  depends_on     = [aws_subnet.publicsubnet, aws_route_table.publicrt, ]
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.publicrt.id
}

#creating a private subnet
resource "aws_subnet" "privatesubnet" {
  depends_on        = [aws_vpc.vpc, ]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.avail_zone

  tags = {
    Name = "privatesubnet_ws"
  }
}

#creating a private route table
resource "aws_route_table" "privatert" {
  depends_on = [aws_vpc.vpc, ]
  vpc_id     = aws_vpc.vpc.id

  tags = {
    Name = "privatert_ws"
  }
}

#private route is not necessary

#associating private route table with private subnet
resource "aws_route_table_association" "privatertsassociation" {
  depends_on     = [aws_subnet.privatesubnet, aws_route_table.privatert, ]
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.privatert.id
}

#creating a web server
resource "aws_instance" "webserver" {
  depends_on                  = [aws_vpc.vpc, aws_security_group.ws_sg, ]
  ami                         = var.linux_ami_id
  instance_type               = var.instance_type
  key_name                    = var.keypair
  subnet_id                   = aws_subnet.publicsubnet.id
  vpc_security_group_ids      = [aws_security_group.ws_sg.id]
  source_dest_check           = false
  associate_public_ip_address = true

  tags = {
    Name = "webserver"
  }
  user_data = file("lampinit.sh")
}

#creating a security group for web server
resource "aws_security_group" "ws_sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "webserver-securitygroup"

  ingress {
    description = "SSH-Ingress CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myip, var.officeip]
  }
  ingress {
    description = "HTTP-Ingress CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.myip, var.officeip]
  }
  ingress {
    description = "HTTPS-Ingress CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.myip, var.officeip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ws_sg"
  }
}
