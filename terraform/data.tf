data "twc_projects" "project" {
  name = var.project_name
}

data "twc_configurator" "server" {
  location = var.location
}

data "twc_os" "ubuntu" {
  name    = "ubuntu"
  version = "26.04"
}

data "twc_database_preset" "postgres" {
  location = var.location
  type     = "postgres"
  cpu      = 1
  ram      = 1024
  disk     = 8 * 1024
}

data "twc_lb_preset" "rasp" {
  location = var.location
}

data "twc_dns_zone" "app" {
  count = var.dns_zone_name != "" && var.dns_record_name != "" ? 1 : 0

  name = var.dns_zone_name
}
