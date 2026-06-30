resource "twc_lb" "rasp" {
  name              = var.load_balancer_name
  algo              = "roundrobin"
  availability_zone = var.availability_zone
  preset_id         = data.twc_lb_preset.rasp.id
  project_id        = data.twc_projects.project.id
  ips               = ["192.168.0.5", "192.168.0.7"]
  is_keepalive      = true
  is_ssl            = false

  health_check {
    proto   = "http"
    path    = var.load_balancer_health_check_path
    port    = 80
    inter   = 10
    timeout = 5
    rise    = 2
    fall    = 3
  }

  local_network {
    id = twc_vpc.rasp.id
  }

  depends_on = [
    twc_server.rasp_vds,
    twc_server.rasp_vds_2,
  ]
}

resource "twc_lb_rule" "http" {
  lb_id          = twc_lb.rasp.id
  balancer_proto = "http"
  balancer_port  = 80
  server_proto   = "http"
  server_port    = 80
}

resource "twc_lb_rule" "https" {
  lb_id          = twc_lb.rasp.id
  balancer_proto = "tcp"
  balancer_port  = 443
  server_proto   = "tcp"
  server_port    = 443
}
