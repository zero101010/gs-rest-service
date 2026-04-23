# Adopt the existing default VPC (no changes made to it)
resource "aws_default_vpc" "default" {}

# Internet gateway — allows the VPC to reach the public internet
resource "aws_internet_gateway" "default" {
  vpc_id = aws_default_vpc.default.id
}

# Default route table — send all non-local traffic through the IGW
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_default_vpc.default.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

# Restore (or adopt) the default subnet in the first AZ of the region
resource "aws_default_subnet" "default" {
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.default]
}

# Elastic IP — guarantees a stable public IP independent of subnet settings
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  depends_on = [aws_internet_gateway.default]
}
