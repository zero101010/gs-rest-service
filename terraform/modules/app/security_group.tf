resource "aws_security_group" "app" {
  name        = "gs-rest-service-sg"
  description = "Allow HTTP/HTTPS from anywhere; SSH only from operator IP"
  vpc_id      = aws_default_vpc.default.id

  # HTTP — needed for redirect to HTTPS
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS — main entry point, Nginx proxies to app on port 777
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH — restricted to operator IP only
  ingress {
    description = "SSH from operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_ip_cidr]
  }

  # All other inbound traffic is implicitly denied by AWS default

  # Allow all outbound (needed for Docker pulls, package installs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gs-rest-service-sg"
  }
}
