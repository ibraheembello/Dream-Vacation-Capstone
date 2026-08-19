# Outputs consumed by the pipeline (ec2_public_ip) and handy for humans.
output "ec2_public_ip" {
  description = "Elastic IP of the Dream Vacation EC2 instance"
  value       = aws_eip.dream.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.dream.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.dream.id
}

output "cloudwatch_alarm_name" {
  description = "Name of the CPU alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "route53_zone_id" {
  description = "ID of the Route 53 hosted zone for the app domain"
  value       = aws_route53_zone.dream.zone_id
}

output "route53_name_servers" {
  description = "Nameservers for the hosted zone. Set these at the domain registrar to make Route 53 authoritative."
  value       = aws_route53_zone.dream.name_servers
}
