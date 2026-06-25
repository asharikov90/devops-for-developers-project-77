resource "twc_firewall" "vm" {
  name        = "VM"
  description = "Allow SSH, HTTP and HTTPS to rasp-vds; allow outbound TCP."

  link {
    id   = twc_server.rasp_vds.id
    type = "server"
  }
}

resource "twc_firewall_rule" "vm_ingress_https" {
  firewall_id = twc_firewall.vm.id
  direction   = "ingress"
  protocol    = "tcp"
  port        = 443
  cidr        = "0.0.0.0/0"
  description = "HTTPS"
}

resource "twc_firewall_rule" "vm_ingress_http" {
  firewall_id = twc_firewall.vm.id
  direction   = "ingress"
  protocol    = "tcp"
  port        = 80
  cidr        = "0.0.0.0/0"
  description = "HTTP"
}

resource "twc_firewall_rule" "vm_ingress_ssh" {
  firewall_id = twc_firewall.vm.id
  direction   = "ingress"
  protocol    = "tcp"
  port        = 22
  cidr        = "0.0.0.0/0"
  description = "SSH"
}

resource "twc_firewall_rule" "vm_egress_tcp" {
  firewall_id = twc_firewall.vm.id
  direction   = "egress"
  protocol    = "tcp"
  cidr        = "0.0.0.0/0"
  description = "All outbound TCP traffic"
}

resource "twc_firewall" "postgres" {
  name        = "Postgres"
  description = "Allow PostgreSQL connections to rasp-postgres."

  link {
    id   = twc_database_cluster.rasp_postgres.id
    type = "dbaas"
  }
}

resource "twc_firewall_rule" "postgres_ingress" {
  firewall_id = twc_firewall.postgres.id
  direction   = "ingress"
  protocol    = "tcp"
  port        = 5432
  cidr        = "0.0.0.0/0"
  description = "Postgres"
}
