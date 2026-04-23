include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/app"
}

inputs = {
  aws_region        = "us-east-1"
  local_ip_cidr     = ""  # Get your current public IP for SSH access
  key_pair_name     = ""  # Name of your EC2 Key Pair in AWS
  deploy_public_key = ""  # GitHub Actions deploy public key
  domain            = ""  # Domain to deploy the application (e.g. gs-rest-service.igor-aws.link)
  certbot_email     = ""  # Email address for Let's Encrypt certificate notifications
}
