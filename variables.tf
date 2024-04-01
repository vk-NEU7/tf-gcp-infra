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

variable "db_instance_flag" {
    type = string
}

variable "db_instance_connections" {
    type = number
}

variable "webapp_pubsub_iam_binding_role" {
    type = string
}

variable "webapp_pubsub_binding_subscription" {
    type = string
}

variable "webapp_pubsub_binding_subscription_role" {
    type = string
}

variable "cloud_function_timeout" {
    type = number
}

variable "max_instance_request_concurrency_limit" {
    type = number
}

variable "available_cpu" {
    type = string
}

variable "vpc_connector_egress_settings" {
    type = string
}

variable "trigger_region" {
    type = string
}

variable "event_type_cloudfunction" {
    type = string
}

variable "retry_policy_event" {
    type = string
}

variable "serverless-vpc-connector-name" {
    type = string
}

variable "ip_cidr_range_serverless" {
    type = string
}
variable "cloud_function_service_account_name" {
    type = string
}

variable "cloud_function_service_account_id" {
    type = string
}

variable "cloudfunction_pubsub_subscriber_binding_role" {
    type = string
  
}

variable "pubsubtopic_service_account_binding_role" {
    type = string
}

variable "iam_binding_invoker_role" {
    type = string
  
}

variable "iam_service_accountuser_role" {
    type = string
}

variable "private_vpc_firewall2_name" {
    type = string
  
}

variable "SMTP_allow_ports" {
    type = list(string)
  
}

variable "SMTP_allow_protocols" {
    type = string
}

variable "SMTP_direction" {
    type = string
}

variable "SMTP_log" {
    type = string
}

variable "SMTP_source_ranges" {
    type = list(string)
}

variable "webapp_instance_manager" {
    type = string
}

variable "SMTP_destination_ranges" {
    type = list(string)
  
}

variable "instance_template_name" {
    type = string
}

variable "instance_machine_type" {
    type = string
}

variable "instance_manager_version" {
    type = string
}

variable "named_port_name" {
    type = string
}

variable "namedport" {
    type = string
}

variable "base_instance_name" {
    type = string
}

variable "autoscaler_name" {
    type = string
}

variable "instance_initial_delay" {
    type = number
}

variable "autoscale_min_replica" {
    type = number
}

variable "autoscale_max_replica" {
    type = number
  
}

variable "autoscale_cooldown" {
    type = number
  
}

variable "cpu_utilization_target" {
    type = number
  
}

variable "webapp_health_check_name" {
    type = string
  
}

variable "timeout_healthcheck" {
    type = number
  
}

variable "healthcheck_interval" {
  type = number
}

variable "healthy_threshold" {
    type = number
  
}

variable "unhealthy_threshold" {
    type = number
  
}

variable "tcp_port" {
    type = string
  
}

variable "tcp_port_name" {
    type = string
  
}

variable "health_check_url" {
    type = string
  
}

variable "lb_subnet_name" {
    type = string
  
}

variable "lb_subnet_ip_cidr" {
    type = string
  
}

variable "lb_subnet_purpose" {
    type = string
  
}
variable "lb_role" {
    type = string
  
}

variable "health_check_firewall_name" {
    type = string
  
}

variable "health_check_firewall_port" {
    type = string
  
}

variable "health_check_direction" {
    type = string
  
}

variable "health_check_source" {
    type = list(string)
  
}

variable "health_check_destination" {
    type = list(string)
  
}

variable "proxy_firewall" {
    type = string
  
}

variable "proxy_firewall_protocol" {
    type = string
  
}

variable "proxy_firewall_port1" {
    type = list(string)
  
}

variable "proxy_firewall_port2" {
    type = list(string)
  
}

variable "proxy_firewall_direction" {
    type = string
  
}

variable "proxy_firewall_source" {
    type = list(string)
  
}

variable "proxy_firewall_destination" {
    type = list(string)
  
}

variable "lb_ip" {
    type = string
  
}

variable "lb_url_map" {
    type = string
  
}

variable "lb_backend_name" {
    type = string
  
}

variable "lb_backend_protocol" {
    type = string
  
}
variable "lb_backend_port_name" {
    type = string
  
}

variable "lb_scheme" {
    type = string
  
}

variable "lb_session" {
    type = string
  
}

variable "lb_timeout" {
    type = number
  
}

variable "lb_balancing_mode" {
    type = string
  
}

variable "capacity_scaler_lb" {
    type = number
  
}

variable "ssl_certificate_name" {
    type = string
  
}

variable "domain_name_ssl" {
    type = list(string)
  
}

variable "lb_https_proxy" {
    type = string
  
}

variable "lb_rule_name" {
    type = string
  
}

variable "lb_rule_protocol" {
    type = string
  
}

variable "rule_scheme" {
    type = string
  
}

variable "rule_port_range" {
    type = string
  
}