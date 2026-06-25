output "server_public_ipv4" {
  description = "Public IPv4 address of rasp-vds."
  value       = twc_server.rasp_vds.main_ipv4
}

output "server_private_ipv4" {
  description = "Private IPv4 address reserved for rasp-vds."
  value       = "192.168.0.5"
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
