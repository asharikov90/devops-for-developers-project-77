resource "twc_database_cluster" "rasp_postgres" {
  name              = "rasp-postgres"
  description       = "PostgreSQL cluster for rasp application."
  type              = "postgres17"
  preset_id         = data.twc_database_preset.postgres.id
  availability_zone = var.availability_zone
  project_id        = data.twc_projects.project.id
  hash_type         = var.db_hash_type
  is_external_ip    = false

  network {
    id = twc_vpc.rasp.id
  }
}

resource "twc_database_instance" "app" {
  cluster_id = twc_database_cluster.rasp_postgres.id
  name       = "app"
}

resource "twc_database_instance" "default_db" {
  cluster_id = twc_database_cluster.rasp_postgres.id
  name       = "default_db"
}

resource "twc_database_user" "gen_user" {
  cluster_id = twc_database_cluster.rasp_postgres.id
  login      = "gen_user"
  password   = var.db_password

  instance {
    instance_id = twc_database_instance.app.id
    privileges  = ["ALL"]
  }

  instance {
    instance_id = twc_database_instance.default_db.id
    privileges  = ["ALL"]
  }
}
