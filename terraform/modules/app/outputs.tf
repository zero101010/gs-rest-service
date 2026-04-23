output "instance_public_ip" {
  description = "Elastic IP of the EC2 instance"
  value       = aws_eip.app.public_ip
}

output "app_url" {
  description = "Service endpoint (IP)"
  value       = "http://${aws_eip.app.public_ip}:777/greeting"
}

output "app_dns_url" {
  description = "Service endpoint (DNS)"
  value       = "http://${aws_route53_record.app.name}:777/greeting"
}

output "ssh_command" {
  description = "SSH command for the operator"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_eip.app.public_ip}"
}

output "deploy_ssh_command" {
  description = "SSH command for the deploy user (GitHub Actions)"
  value       = "ssh deploy@${aws_eip.app.public_ip}"
}

