# Look up the existing hosted zone for igor-aws.link
data "aws_route53_zone" "main" {
  name         = "igor-aws.link."
  private_zone = false
}

# A record pointing gs-rest-service.igor-aws.link → Elastic IP
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "gs-rest-service.igor-aws.link"
  type    = "A"
  ttl     = 60
  records = [aws_eip.app.public_ip]
}
