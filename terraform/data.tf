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
