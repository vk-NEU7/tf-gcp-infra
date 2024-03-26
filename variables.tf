variable "region" {
  type = string
  description = "Google cloud region"
}

variable "zone" {
    type = string
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

variable "webapp_subnet" {
    type = string
    default = "webapp"
    description = "Name of webapp subnet"
}

variable "db_subnet" {
    type = string
    default = "db"
    description = "Name of db subnet"
}

variable "webapp_subnet_route" {
    type = string
    default = "webapp-route"
    description = "Name of webpp subnet route"
}

variable "delete_default_route" {
    type = bool
    default = false
}

variable "next_hop_gateway" {
    type = string
}

variable "vpc_name" {
    type = string
}

variable "webapp_instance_name" {
    type = string
}

variable "webapp_instance_type" {
    type = string
}

variable "webapp_instance_tags" {
    type = list(string)
}

variable "webapp_instance_image" {
    type = string
}

variable "webapp_instance_size" {
    type = number
}

variable "webapp_instance_bootdisk_type" {
    type = string
}

variable "webapp_instance_networktier" {
    type = string
}

variable "webapp_firewall_name" {
    type = string
}

variable "webapp_firewall_protocol" {
    type = string
}

variable "webapp_firewall_ssh" {
    type = string
}

variable "webapp_firewall_protocol_allow_ports" {
    type = list(string)
}

variable "webapp_firewall_protocol_deny_ports" {
    type = list(string)
}

variable "webapp_firewall_target_tags" {
    type = list(string)
}

variable "webapp_firewall_source_tags" {
    type = list(string)
  
}

variable "db_firewall_name" {
    type = string
}

variable "db_firewall_protocol" {
    type = string
}

variable "db_firewall_source_cidr" {
    type = list(string)
}

variable "db_firewall_ports" {
    type = list(string)
}

variable "db_instance_name" {
    type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
    type = string
}

variable "db_password" {
    type = string
}

variable "db_deletion_policy" {
    type = string
}

variable "db_version" {
    type = string
}

variable "db_instance_tier" {
    type = string
}

variable "db_instance_disk" {
    type = string
}

variable "db_disk_size" {
    type = number
}

variable "db_availability" {
    type = string
}

variable "db_deletion_protection" {
    type = bool  
}

variable "vpc_peering_ip" {
    type = string
}

variable "vpc_ip_purpose" {
    type = string  
}

variable "vpc_ip_addresstype" {
    type = string
}

variable "private_ip_length" {
    type = number
}

variable "networking_connection_service" {
    type = string
}

variable "deletion_policy_abandon" {
    type = string
}

variable "webapp_instance_service_accountid" {
  type = string
}

variable "webapp_instance_service_accountname" {
    type = string
}

variable "logging_admin_binding" {
    type = string
}

variable "webapp_monitoring_binding" {
    type = string

}

variable "webapp_instance_scopes" {
    type = list(string)
}
variable "dns_zone_webapp" {
    type = string
}

variable "dns_record_webapp_A" {
    type = string
}

variable "dns_record_webapp_A_ttl" {
    type = number
}

variable "mailgun_api_key" {
    type = string
}

variable "mailgun_email" {
    type = string
}

variable "pubSub_topic_name" {
    type = string
}

variable "environment_name" {
    type = string
}

variable "messge_retention_dur" {
    type = string
}

variable "pubsub_subscription_name" {
    type = string
}

variable "msg_acknowledge_deadline" {
    type = number
}

variable "bucket_name" {
    type = string
}

variable "bucket_location" {
    type = string
}

variable "bucket_uniform_access_level" {
    type = bool
}

variable "bucket_object_name" {
    type = string
}

variable "cloud_function_source" {
    type = string
}

variable "cloud_function_name" {
    type = string
}

variable "cloud_function_description" {
    type = string
}

variable "cloud_function_runtime" {
    type = string
}

variable "cloud_function_entrypoint" {
    type = string
}

variable "build_test_config" {
    type = string
}

variable "cloud_function_instance_mincount" {
    type = number
}

variable "cloud_function_instance_maxcount" {
    type = number
}

variable "cloud_function_instance_memory" {
    type = string
}