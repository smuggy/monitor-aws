output "prometheus_public_ip" {
  description = "Public ip of the prometheus server."
  value       = aws_instance.prometheus_server.public_ip
}

output "consul_public_ips" {
  description = "Public ips for consul servers"
  value       = local.consul_public_ips
}