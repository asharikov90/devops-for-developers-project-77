resource "twc_dns_rr" "app" {
  count = var.dns_zone_name != "" && var.dns_record_name != "" ? 1 : 0

  zone_id = data.twc_dns_zone.app[0].id
  name    = var.dns_record_name
  type    = "A"
  value   = twc_lb.rasp.ip
}
