provider "aws" {
  region = var.region
}

resource "aws_key_pair" "qt_webserver" {
  key_name   = "server_key"
  public_key = file("${path.module}/files/${var.pub_key}")
}

resource "aws_security_group" "qt_security_group" {
  name_prefix = "qt-sg"
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "qt_webserver" {
  count = 1

  user_data = <<-EOL
  #!/bin/bash -xe
    sudo apt-get update
    sudo apt-get install -y nginx
  EOL


  ami                         = "ami-0eb260c4d5475b901"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.qt_webserver.key_name
  vpc_security_group_ids      = [aws_security_group.qt_security_group.id]
  associate_public_ip_address = true
  tags = {
    Name = "qt-server-${count.index + 1}"
  }
}

output "instance_ip" {
  value = aws_instance.qt_webserver[0].public_ip
}


# Create S3 bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "qt-mybucket"

  tags = {
    Name = "qt-example-bucket"
  }
}

# Upload file to S3 bucket
resource "aws_s3_object" "example_file" {
  bucket = aws_s3_bucket.example_bucket.id
  key    = "myfile.sh"
  source = "${path.module}/files/myfile.sh"
}


