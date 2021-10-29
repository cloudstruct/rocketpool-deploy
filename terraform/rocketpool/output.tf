output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ssh_private_key" {
  sensitive = true
  value     = try(tls_private_key.ssh_keypair.0.private_key_pem, "USER_PROVIDED")
}

output "node_public_ips" {
  value = join(",", [for key, val in aws_eip.node : val.public_ip])
}
