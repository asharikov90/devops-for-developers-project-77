output "server_public_ipv4" {
  description = "Public IPv4 address of rasp-vds."
  value       = twc_server.rasp_vds.main_ipv4
}

output "server_2_public_ipv4" {
  description = "Public IPv4 address of rasp-vds-2."
  value       = twc_server.rasp_vds_2.main_ipv4
}

output "server_private_ipv4" {
  description = "Private IPv4 address reserved for rasp-vds."
  value       = "192.168.0.5"
}

output "server_2_private_ipv4" {
  description = "Private IPv4 address reserved for rasp-vds-2."
  value       = "192.168.0.7"
}

output "load_balancer_public_ipv4" {
  description = "Public IPv4 address of the load balancer."
  value       = twc_lb.rasp.ip
}

output "ansible_inventory" {
  description = "Inventory snippet for deploying to both backend servers."
  value       = <<-EOT
    [webservers]
    web1 ansible_host=${twc_server.rasp_vds.main_ipv4} ansible_user=ansible
    web2 ansible_host=${twc_server.rasp_vds_2.main_ipv4} ansible_user=ansible
  EOT
}

output "postgres_private_ipv4" {
  description = "Private PostgreSQL address expected from the panel."
  value       = "192.168.0.6"
}

output "postgres_port" {
  description = "PostgreSQL port."
  value       = twc_database_cluster.rasp_postgres.port
}

output "postgres_login" {
  description = "PostgreSQL application user."
  value       = twc_database_user.gen_user.login
}
