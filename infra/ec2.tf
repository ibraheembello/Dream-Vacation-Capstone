# Part 2: the EC2 instance and its security group.
#   Latest Ubuntu 24.04 LTS, t3.micro, SSH + HTTP open, Docker installed by
#   user-data. An Elastic IP keeps the address stable across applies so the
#   deploy job and any DNS stay valid.

# Latest Canonical Ubuntu 24.04 LTS image, resolved at plan time.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "dream" {
  key_name   = "dream-key"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "dream" {
  name        = "dream-sg"
  description = "Allow SSH (22), HTTP (80) and HTTPS (443)"
  vpc_id      = aws_vpc.dream.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dream-sg"
  }
}

resource "aws_instance" "dream" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.dream.id
  vpc_security_group_ids = [aws_security_group.dream.id]
  key_name               = aws_key_pair.dream.key_name
  user_data              = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "dream-ec2"
  }
}

resource "aws_eip" "dream" {
  instance   = aws_instance.dream.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.dream]

  tags = {
    Name = "dream-eip"
  }
}
