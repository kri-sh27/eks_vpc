provider "aws" {
  region     = var.region
  access_key = "abcde"
  secret_key = "abcded"
}

resource "aws_instance" "myec2" {
  ami                         = var.os-name
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.demo-subnet-1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.demo-vpc-sg.id]

  tags = {
    Name = "my-first-ec2"
  }
}

//create vpc
resource "aws_vpc" "demo-vpc" {
  cidr_block = var.vpc-cidr
}

//create subnet-1
resource "aws_subnet" "demo-subnet-1" {
  vpc_id                  = aws_vpc.demo-vpc.id
  cidr_block              = var.subnet1-cidr
  availability_zone       = var.subnet_az
  map_public_ip_on_launch = true

  tags = {
    Name = "demo-subnet-1"
  }
}

//create subnet-2
resource "aws_subnet" "demo-subnet-2" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = var.subnet2-cidr
  availability_zone = var.subnet-2_az
  map_public_ip_on_launch = true

  tags = {
    Name = "demo-subnet-2"
  }
}

//create internet gateway
resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "demo-igw"
  }
}

//route table
resource "aws_route_table" "demo-rt" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-igw.id
  }

  tags = {
    Name = "demo-rt"
  }
}

//subnet association with rt
resource "aws_route_table_association" "demo-rt_association-1" {
  subnet_id      = aws_subnet.demo-subnet-1.id
  route_table_id = aws_route_table.demo-rt.id
}

//subnet association with rt
resource "aws_route_table_association" "demo-rt_association-2" {
  subnet_id      = aws_subnet.demo-subnet-2.id
  route_table_id = aws_route_table.demo-rt.id
}


//security group
resource "aws_security_group" "demo-vpc-sg" {
  name   = "demo-vpc-sg"
  vpc_id = aws_vpc.demo-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
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
    Name = "allow_tls"
  }
}

module "sgs" {
  source = "./sg_eks"
  vpc_id = aws_vpc.demo-vpc.id

}

module "eks" {
  source     = "./eks"
  sg_ids     = module.sgs.security_group_public
  vpc_id     = aws_vpc.demo-vpc.id
  subnet_ids = [aws_subnet.demo-subnet-1.id, aws_subnet.demo-subnet-2.id]

}


