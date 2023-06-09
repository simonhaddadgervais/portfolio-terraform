

resource "aws_instance" "jenkins" {
  ami = "ami-01bbe8d061400c341"

  instance_type = "t3.medium"

  root_block_device {
    volume_size = 20
  }

  key_name = "jenkins-server"
  tags = {
    Name = "Jenkins"
  }

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
}


resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["89.64.67.87/32"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to any IP
  }
}

