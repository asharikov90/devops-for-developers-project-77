resource "twc_server" "rasp_vds" {
  name              = "rasp-vds"
  hostname          = "kvmhi-150"
  comment           = "Синхронизация яндекс расписаний"
  availability_zone = var.availability_zone
  os_id             = data.twc_os.ubuntu.id
  project_id        = data.twc_projects.project.id
  bandwidth         = 1000
  cloud_init = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    ssh_public_key = var.ssh_public_key
  })

  configuration {
    configurator_id = data.twc_configurator.server.id
    cpu             = 1
    ram             = 1024
    disk            = 15 * 1024
  }

  local_network {
    id   = twc_vpc.rasp.id
    ip   = "192.168.0.5"
    mode = "dnat_and_snat"
  }
}
