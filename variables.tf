variable "region" {
  type = string
  description = "Google cloud region"
}

variable "routing_mode_RGL" {
    type = string
    description = "routing_mode_RGL"
}

variable "auto_create_subnets" {
    type = bool
    description = "value"
}

variable "project_name" {
    type = string
    description = "value"
  
}

variable "ip_cidr_range_webapp" {
    type = string
    description = "IP CIDR range for web app"
}

variable "ip_cidr_range_db" {
    type = string
    description = "ip CIDR range for database"
}

variable "webapp_destination" {
    type = string
    description = "Route for webapp subnet"
}