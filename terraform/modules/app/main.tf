# Latest Amazon Linux 2023 AMI (Free Tier eligible)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair_name
  subnet_id              = aws_default_subnet.default.id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  user_data = templatefile("${path.module}/user_data.sh", {
    deploy_public_key = var.deploy_public_key
    domain            = var.domain
    certbot_email     = var.certbot_email
  })

  # Enforce IMDSv2 — blocks SSRF-based metadata theft
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "gs-rest-service"
  }
}
