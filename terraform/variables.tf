variable "project_name" {
  description = "Existing Timeweb Cloud project name."
  type        = string
  default     = "Общий проект"
}

variable "location" {
  description = "Timeweb Cloud location for VPC, server and DB presets."
  type        = string
  default     = "ru-3"
}

variable "availability_zone" {
  description = "Availability zone shown in the panel as Москва - MSK-1."
  type        = string
  default     = "msk-1"
}

variable "ssh_public_key" {
  description = "Public SSH key for the ansible user created by cloud-init."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the gen_user PostgreSQL user."
  type        = string
  sensitive   = true
}

variable "db_hash_type" {
  description = "Optional database password hash type. Leave null to use Timeweb default."
  type        = string
  default     = null
}

variable "load_balancer_name" {
  description = "Name for the Timeweb Cloud load balancer."
  type        = string
  default     = "rasp-lb"
}

variable "load_balancer_health_check_path" {
  description = "HTTP path used by the load balancer health check."
  type        = string
  default     = "/"
}

variable "dns_zone_name" {
  description = "Existing Timeweb Cloud DNS zone name. Leave empty to skip DNS record creation."
  type        = string
  default     = ""
}

variable "dns_record_name" {
  description = "DNS record label inside dns_zone_name, for example @ or rasp. Leave empty to skip DNS record creation."
  type        = string
  default     = ""
}
