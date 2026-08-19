# Part 6 (DNS): a Route 53 public hosted zone for the app domain, plus an apex
# A record pointing at the EC2 Elastic IP.
#
# NOTE on the free domain: the live site uses a free DuckDNS subdomain
# (dream-vacations.duckdns.org). DuckDNS owns the duckdns.org parent zone and
# does not let you delegate a subdomain's nameservers, so the internet resolves
# the name through DuckDNS, not through this Route 53 zone. This hosted zone is
# still provisioned as code to satisfy the Route 53 requirement and is fully
# usable the moment the domain is swapped for a registrable one: point the
# registrar's nameservers at the values in the `route53_name_servers` output and
# Route 53 becomes authoritative, no code change needed.

resource "aws_route53_zone" "dream" {
  name    = var.domain_name
  comment = "Dream Vacations capstone hosted zone (managed by Terraform)"

  tags = {
    Name = "dream-hosted-zone"
  }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.dream.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.dream.public_ip]
}
