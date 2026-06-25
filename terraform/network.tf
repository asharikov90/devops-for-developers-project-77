resource "twc_vpc" "rasp" {
  name        = "rasp-network"
  description = "Private network for rasp-vds and rasp-postgres."
  subnet_v4   = "192.168.0.0/24"
  location    = var.location
}
