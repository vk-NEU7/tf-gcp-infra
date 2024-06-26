provider "google" {
    project = var.project_name
    region = var.region
}

resource "random_string" "random_suffix" {
    length = 4
    lower = true
    upper = false
    special = false
}

resource "random_password" "password" {
  length           = 8
  special          = true
  override_special = "-@&4"
}

data "google_project" "project-id" {
}

resource "google_compute_network" "private_vpc" {
    name = var.vpc_name
    auto_create_subnetworks = var.auto_create_subnets
    routing_mode = var.routing_mode_RGL
    delete_default_routes_on_create = var.delete_default_route
}

resource "google_compute_global_address" "private_ip_address" {
  name          = var.vpc_peering_ip
  purpose       = var.vpc_ip_purpose
  address_type  = var.vpc_ip_addresstype
  prefix_length = var.private_ip_length
  network       = google_compute_network.private_vpc.id
}

resource "google_service_networking_connection" "networking_connection" {
  network                 = google_compute_network.private_vpc.id
  service                 = var.networking_connection_service
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  deletion_policy = var.deletion_policy_abandon
}

resource "google_compute_subnetwork" "webapp_subnet" {
    name = var.webapp_subnet
    ip_cidr_range = var.ip_cidr_range_webapp
    network = google_compute_network.private_vpc.id
    region = var.region
    private_ip_google_access = true
}

resource "google_compute_subnetwork" "db_subnet" {
    name = var.db_subnet
    ip_cidr_range = var.ip_cidr_range_db
    network = google_compute_network.private_vpc.id
    region = var.region
    private_ip_google_access = true
}


resource "google_compute_route" "webapp_subnet_route" {
    name = var.webapp_subnet_route
    network = google_compute_network.private_vpc.id
    dest_range = var.webapp_destination
    next_hop_gateway = var.next_hop_gateway
}

resource "google_compute_firewall" "private_vpc_firewall" {
    name = var.webapp_firewall_name
    network = google_compute_network.private_vpc.name

    allow {
      protocol = var.webapp_firewall_protocol
      ports = var.webapp_firewall_protocol_allow_ports
    }
    source_tags = var.webapp_firewall_source_tags
    #target_tags = var.webapp_firewall_target_tags
}

resource "google_compute_firewall" "private_vpc_firewall1" {
    name = var.webapp_firewall_ssh
    network = google_compute_network.private_vpc.name

    deny {
      protocol = var.webapp_firewall_protocol
      ports = var.webapp_firewall_protocol_deny_ports
    }

    source_tags = var.webapp_firewall_source_tags
    target_tags = var.webapp_firewall_target_tags
}

resource "google_compute_firewall" "private_vpc_firewall2" {
  name = var.private_vpc_firewall2_name
  network = google_compute_network.private_vpc.name

  allow {
    ports = var.SMTP_allow_ports
    protocol = var.SMTP_allow_protocols
  }

  direction = var.SMTP_direction

  log_config {
    metadata = var.SMTP_log
  }

  source_ranges = var.SMTP_source_ranges
  destination_ranges = var.SMTP_destination_ranges
  
}

resource "google_compute_firewall" "private_vpc_firewall_blockdbtraffic" {
    name = var.db_firewall_name
    network = google_compute_network.private_vpc.name

    allow {
      protocol = var.db_firewall_protocol
      ports = var.db_firewall_ports
    }
    source_ranges = var.db_firewall_source_cidr
}

resource "google_sql_database" "app_db" {
    name = var.db_name
    instance = google_sql_database_instance.db_instance.name  
    deletion_policy = var.db_deletion_policy
}

resource "google_sql_database_instance" "db_instance" {
    name = var.db_instance_name
    region = var.region
    database_version = var.db_version
    depends_on = [ google_service_networking_connection.networking_connection,
    google_kms_crypto_key.sql_crypto_key ]
    
    settings {
      tier = var.db_instance_tier
      disk_type = var.db_instance_disk
      disk_size = var.db_disk_size

      database_flags {
        name  = var.db_instance_flag
        value = var.db_instance_connections
      }

      ip_configuration {
        ipv4_enabled = false
        private_network = google_compute_network.private_vpc.id
      }
      availability_type = var.db_availability
    }
    encryption_key_name = google_kms_crypto_key.sql_crypto_key.id
  
  deletion_protection = var.db_deletion_protection
}

resource "google_sql_user" "user_details" {
    instance = google_sql_database_instance.db_instance.name
    name = var.db_user
    password = random_password.password.result
    deletion_policy = var.deletion_policy_abandon
    depends_on = [ google_sql_database_instance.db_instance ]  
}

output "db_private_ip" {
  value = "${google_sql_database_instance.db_instance.private_ip_address}"
}

resource "google_service_account" "webapp_instance_service_account" {
  account_id = var.webapp_instance_service_accountid
  display_name = var.webapp_instance_service_accountname
}

resource "google_project_iam_binding" "webapp_logging_binding" {
  project = data.google_project.project-id.project_id
  role = var.logging_admin_binding
  members = [
    "serviceAccount:${google_service_account.webapp_instance_service_account.email}"
  ]
}

resource "google_project_iam_binding" "webapp_monitoring_binding" {
  project = data.google_project.project-id.project_id
  role = var.webapp_monitoring_binding
  members = [
    "serviceAccount:${google_service_account.webapp_instance_service_account.email}"
  ]
}

resource "google_project_iam_binding" "webapp_pubsub_iam_binding" {
  project = data.google_project.project-id.project_id
  role = var.webapp_pubsub_iam_binding_role
  members = [
    "serviceAccount:${google_service_account.webapp_instance_service_account.email}"
  ] 
}


resource "google_pubsub_subscription_iam_binding" "webapp_pubsub_binding" {
  subscription = var.webapp_pubsub_binding_subscription
  role = var.webapp_pubsub_binding_subscription_role
  members = [
    "serviceAccount:${google_service_account.webapp_instance_service_account.email}"
  ]
}

# resource "google_compute_instance" "webapp_instance" {
#     name = var.webapp_instance_name
#     machine_type = var.webapp_instance_type
#     zone = var.zone

#     tags = var.webapp_instance_tags
#     allow_stopping_for_update = true

#     depends_on = [google_service_account.webapp_instance_service_account, 
#     google_project_iam_binding.webapp_logging_binding, 
#     google_project_iam_binding.webapp_monitoring_binding,
#     google_pubsub_subscription_iam_binding.webapp_pubsub_binding]
#     service_account {
#       email = google_service_account.webapp_instance_service_account.email
#       scopes = var.webapp_instance_scopes
#     }
#     boot_disk {
#         initialize_params {
#           image = var.webapp_instance_image
#           size = var.webapp_instance_size
#           type = var.webapp_instance_bootdisk_type
#         }
#     }

#     network_interface {
#         network = google_compute_network.private_vpc.name
#         subnetwork = google_compute_subnetwork.webapp_subnet.name
#         access_config {
#         network_tier = var.webapp_instance_networktier
#       }
#     }

#     metadata_startup_script = <<-EOT
#     #!/bin/bash
#     sudo truncate -s 0 /opt/webapp/application.properties
#     sudo echo "spring.datasource.driver-class-name=org.postgresql.Driver" >> /opt/webapp/application.properties
#     sudo echo "spring.datasource.url=jdbc:postgresql://${google_sql_database_instance.db_instance.private_ip_address}:5432/${var.db_name}" >> /opt/webapp/application.properties
#     sudo echo "spring.datasource.username=${var.db_user}" >> /opt/webapp/application.properties
#     sudo echo "spring.datasource.password=${random_password.password.result}" >> /opt/webapp/application.properties
#     sudo echo "spring.jpa.properties.hibernate.dialect = org.hibernate.dialect.PostgreSQLDialect" >> /opt/webapp/application.properties
#     sudo echo "spring.jpa.hibernate.ddl-auto=update" >> /opt/webapp/application.properties
#     sudo echo "topic-name=${var.pubSub_topic_name}" >> /opt/webapp/application.properties
#     sudo echo "environment=${var.environment_name}" >> /opt/webapp/application.properties
#     EOT
# }

data "google_dns_managed_zone" "webapp_zone" {
  name = var.dns_zone_webapp
}

resource "google_dns_record_set" "zone_instance" {
  name = data.google_dns_managed_zone.webapp_zone.dns_name
  managed_zone = data.google_dns_managed_zone.webapp_zone.name
  type = var.dns_record_webapp_A
  ttl = var.dns_record_webapp_A_ttl
  rrdatas = [
    # google_compute_instance.webapp_instance.network_interface[0].access_config[0].nat_ip
    google_compute_global_address.lb_ip_address.address
  ]
}

resource "google_pubsub_topic" "pubsub_topic" {
  name                       = var.pubSub_topic_name
  message_retention_duration = var.messge_retention_dur  # Set retention for 7 days
}

resource "google_pubsub_subscription" "pubsub_subscription" {
  name = var.pubsub_subscription_name
  topic = google_pubsub_topic.pubsub_topic.id

  ack_deadline_seconds = var.msg_acknowledge_deadline
 
}

resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name
  location = var.bucket_location
  uniform_bucket_level_access = var.bucket_uniform_access_level
  depends_on = [ google_kms_crypto_key_iam_binding.bucket_crypto_key ]
  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_crypto_key.id
  }
}



resource "google_storage_bucket_object" "function_object" {
  name = var.bucket_object_name
  bucket = google_storage_bucket.bucket.name
  source = var.cloud_function_source
}


resource "google_cloudfunctions2_function" "lambda_function" {
  name = var.cloud_function_name
  location = var.region
  description = var.cloud_function_description

  depends_on = [ google_vpc_access_connector.serverless-vpc-connector,
  google_sql_database_instance.db_instance ]
  build_config {
    runtime = var.cloud_function_runtime
    entry_point = var.cloud_function_entrypoint
    environment_variables = {
        BUILD_CONFIG_TEST = var.build_test_config
    }

    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.function_object.name
      }
    }
  }

  service_config {
    min_instance_count = var.cloud_function_instance_mincount
    max_instance_count = var.cloud_function_instance_maxcount
    available_memory = var.cloud_function_instance_memory
    timeout_seconds = var.cloud_function_timeout
    max_instance_request_concurrency = var.max_instance_request_concurrency_limit
    available_cpu = var.available_cpu
    service_account_email = google_service_account.cloud_function_service_account.email
    environment_variables = {
      db_ip = "${google_sql_database_instance.db_instance.private_ip_address}"
      password = "${random_password.password.result}"
      mailgun_email = var.mailgun_email
      api_key = var.mailgun_api_key
      verification_link = var.verification_link
    }
    vpc_connector = "projects/${data.google_project.project-id.project_id}/locations/${var.region}/connectors/${google_vpc_access_connector.serverless-vpc-connector.name}"
    vpc_connector_egress_settings = var.vpc_connector_egress_settings
  }

  event_trigger {
    trigger_region = var.trigger_region
    event_type = var.event_type_cloudfunction
    pubsub_topic = google_pubsub_topic.pubsub_topic.id
    retry_policy = var.retry_policy_event
  }
  
}

resource "google_vpc_access_connector" "serverless-vpc-connector" {
  project = data.google_project.project-id.project_id
  name = var.serverless-vpc-connector-name
  region = var.region
  network = google_compute_network.private_vpc.name
  ip_cidr_range = var.ip_cidr_range_serverless
}

resource "google_service_account" "cloud_function_service_account" {
  account_id = var.cloud_function_service_account_id
  display_name = var.cloud_function_service_account_name
}

# resource "google_cloudfunctions_function_iam_binding" "iam_binding_cloudfunction_role1" {
#   project = google_cloudfunctions2_function.lambda_function1.project
#   region = var.region
#   cloud_function = google_cloudfunctions2_function.lambda_function1.name
#   role = "roles/iam.serviceAccountUser"
#   members = [
#     "serviceAccount:${google_service_account.cloud_function_service_account.email}"
#   ]
# }

# resource "google_cloudfunctions_function_iam_binding" "iam_binding_cloudfunction_role2" {
#   project = google_cloudfunctions2_function.lambda_function1.project
#   region = var.region
#   cloud_function = google_cloudfunctions2_function.lambda_function1.name
#   role = "roles/cloudfunctions.admin"
#   members = [
#     "serviceAccount:${google_service_account.cloud_function_service_account.email}"
#   ]
# }

# resource "google_pubsub_subscription_iam_binding" "cloudfunction_pubsub_subscriber_binding" {
#   subscription = var.pubsub_subscription_name
#   role = var.cloudfunction_pubsub_subscriber_binding_role
#   members = [
#     "serviceAccount:${google_service_account.cloud_function_service_account.email}"
#   ]
# }

resource "google_pubsub_topic_iam_binding" "pubsubtopic_service_account_binding" {
  project = google_pubsub_topic.pubsub_topic.project
  topic = google_pubsub_topic.pubsub_topic.name
  role = var.pubsubtopic_service_account_binding_role
  members = [
    "serviceAccount:${google_service_account.cloud_function_service_account.email}"
  ]
}

resource "google_project_iam_binding" "iam_binding_invoker" {
  project = data.google_project.project-id.project_id
  role = var.iam_binding_invoker_role
  members = [
    "serviceAccount:${google_service_account.cloud_function_service_account.email}"
  ] 
}

resource "google_service_account_iam_member" "iam_service_accountuser" {
  service_account_id = google_service_account.cloud_function_service_account.id
  role = var.iam_service_accountuser_role
  member = google_service_account.cloud_function_service_account.member
}

resource "google_compute_region_instance_template" "webapp_instance_template" {
  name = var.instance_template_name
  machine_type = var.instance_machine_type

  disk {
    source_image = var.webapp_instance_image
    disk_size_gb = var.webapp_instance_size
    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.crypto_key.id
    }
  }
  region = var.region
  network_interface {
    network = google_compute_network.private_vpc.name
    subnetwork = google_compute_subnetwork.webapp_subnet.name
    access_config {
      network_tier = var.webapp_instance_networktier
    }
  }
  depends_on = [google_service_account.webapp_instance_service_account, 
    google_project_iam_binding.webapp_logging_binding, 
    google_project_iam_binding.webapp_monitoring_binding,
    google_pubsub_subscription_iam_binding.webapp_pubsub_binding]
  service_account {
    email = google_service_account.webapp_instance_service_account.email
    scopes = var.webapp_instance_scopes
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo truncate -s 0 /opt/webapp/application.properties
    sudo echo "spring.datasource.driver-class-name=org.postgresql.Driver" >> /opt/webapp/application.properties
    sudo echo "spring.datasource.url=jdbc:postgresql://${google_sql_database_instance.db_instance.private_ip_address}:5432/${var.db_name}" >> /opt/webapp/application.properties
    sudo echo "spring.datasource.username=${var.db_user}" >> /opt/webapp/application.properties
    sudo echo "spring.datasource.password=${random_password.password.result}" >> /opt/webapp/application.properties
    sudo echo "spring.jpa.properties.hibernate.dialect = org.hibernate.dialect.PostgreSQLDialect" >> /opt/webapp/application.properties
    sudo echo "spring.jpa.hibernate.ddl-auto=update" >> /opt/webapp/application.properties
    sudo echo "topic-name=${var.pubSub_topic_name}" >> /opt/webapp/application.properties
    sudo echo "environment=${var.environment_name}" >> /opt/webapp/application.properties
    EOT

}

resource "google_compute_region_instance_group_manager" "webapp_manager" {
  name = var.webapp_instance_manager
  region = var.region

  version {
    instance_template = google_compute_region_instance_template.webapp_instance_template.id
    name = var.instance_manager_version
  }

  named_port {
    name = var.named_port_name
    port = var.namedport
  }

  auto_healing_policies {
    health_check = google_compute_health_check.webapp_health_check.id
    initial_delay_sec = var.instance_initial_delay
  }

  base_instance_name = var.base_instance_name
  
}

resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name = var.autoscaler_name
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_manager.id

  autoscaling_policy {
    min_replicas = var.autoscale_min_replica
    max_replicas = var.autoscale_max_replica
    cooldown_period = var.autoscale_cooldown

    cpu_utilization {
      target = var.cpu_utilization_target
    }
  }
}

resource "google_compute_health_check" "webapp_health_check" {
  name = var.webapp_health_check_name
  timeout_sec = var.timeout_healthcheck
  check_interval_sec = var.healthcheck_interval
  healthy_threshold = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold

  tcp_health_check {
    port = var.tcp_port
    port_name = var.tcp_port_name
    request = var.health_check_url
  }
  
}

# resource "google_compute_region_health_check" "webapp_regional_health_check" {
#   name = "webapp-regional-health-check"
#   timeout_sec = 5
#   check_interval_sec = 20
#   healthy_threshold = 5
#   unhealthy_threshold = 5
#   region = var.region

#   tcp_health_check {
#     port = "8080"
#     port_name = "tcp-port"
#     request = "/healthz"
#   }

# }

########

resource "google_compute_subnetwork" "lb_subnet" {
  name = var.lb_subnet_name
  ip_cidr_range = var.lb_subnet_ip_cidr
  region = var.region
  purpose = var.lb_subnet_purpose
  network = google_compute_network.private_vpc.id
  role = var.lb_role
}

resource "google_compute_firewall" "health_check_firewall" {
  name = var.health_check_firewall_name
  allow {
    protocol = var.health_check_firewall_port
  }
  direction = var.health_check_direction
  network = google_compute_network.private_vpc.id
  source_ranges = var.health_check_source
  destination_ranges = var.health_check_destination
}

resource "google_compute_firewall" "allow_proxy" {
  name = var.proxy_firewall
  allow {
    ports = var.proxy_firewall_port1
    protocol = var.proxy_firewall_protocol
  }

  allow {
    protocol = var.proxy_firewall_protocol
    ports = var.proxy_firewall_port2
  }

  direction = var.proxy_firewall_direction
  network = google_compute_network.private_vpc.id
  source_ranges = var.proxy_firewall_source
  destination_ranges = var.proxy_firewall_destination
  
}


resource "google_compute_global_address" "lb_ip_address" {
  name = var.lb_ip
}

output "lb-ip" {
  value = "${google_compute_global_address.lb_ip_address}"
  
}

resource "google_compute_url_map" "lb_url_map" {
  name = var.lb_url_map
  default_service = google_compute_backend_service.lb_backend.id
  
}

# resource "google_compute_region_target_http_proxy" "http_proxy" {
#   name = "lb-http"
#   region = var.region
#   url_map = google_compute_region_url_map.lb_url_map.id
  
# }

# resource "google_compute_global_forwarding_rule" "lb_forwarding_rule" {
#   name = "lb-forwarding-rule"
#   ip_protocol = "TCP"
#   load_balancing_scheme = "EXTERNAL_MANAGED"
#   port_range = "443"
#   target = google_compute_target_https_proxy.https_proxy_lb.id
#   # network = google_compute_network.private_vpc.id
#   ip_address = google_compute_address.lb_ip_address.id
# }

resource "google_compute_backend_service" "lb_backend" {
  name = var.lb_backend_name
  protocol = var.lb_backend_protocol
  port_name = var.lb_backend_port_name
  load_balancing_scheme = var.lb_scheme
  health_checks = [google_compute_health_check.webapp_health_check.id]
  session_affinity = var.lb_session
  timeout_sec = var.lb_timeout
  backend {
    group = google_compute_region_instance_group_manager.webapp_manager.instance_group
    balancing_mode = var.lb_balancing_mode
    capacity_scaler = var.capacity_scaler_lb
  }
  
}


########

# resource "tls_private_key" "privatekey_tls" {
#   algorithm = "RSA"
#   rsa_bits = 2048
# }

# resource "tls_self_signed_cert" "tls_certificate" {
#   private_key_pem = tls_private_key.privatekey_tls.private_key_pem
#   validity_period_hours = 12
#   early_renewal_hours = 3

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]
#   dns_names = ["skynetx.me"]
#   subject {
#     common_name = "skynetx.me"
#     organization = "student"
#   }
# }

# resource "google_compute_region_ssl_certificate" "ssl_certificate" {
#   name_prefix = "google-ssl-certificate"
#   private_key = tls_private_key.privatekey_tls.private_key_pem
#   certificate = tls_self_signed_cert.tls_certificate.cert_pem
#   region = var.region
#   lifecycle {
#     create_before_destroy = true
#   }
# }


resource "google_compute_managed_ssl_certificate" "lb_ssl_certificate" {
  name = var.ssl_certificate_name
  managed {
    domains = var.domain_name_ssl
  }
}

# resource "google_compute_region_target_https_proxy" "https_proxy" {
#   name = "https-lbs"
#   region = var.region
#   url_map = google_compute_region_url_map.lb_url_map.id
#   ssl_certificates = [google_compute_managed_ssl_certificate.lb_ssl_certificate.name]
#   depends_on = [ google_compute_managed_ssl_certificate.lb_ssl_certificate ]
# }

resource "google_compute_target_https_proxy" "https_proxy_lb" {
  name = var.lb_https_proxy
  depends_on = [ google_compute_managed_ssl_certificate.lb_ssl_certificate ]
  url_map = google_compute_url_map.lb_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_ssl_certificate.name]
}

resource "google_compute_global_forwarding_rule" "lb-lb_forwarding_rule" {
  name = var.lb_rule_name
  ip_protocol = var.lb_rule_protocol
  load_balancing_scheme = var.rule_scheme
  port_range = var.rule_port_range
  target = google_compute_target_https_proxy.https_proxy_lb.id
  ip_address = google_compute_global_address.lb_ip_address.id
}


resource "google_kms_key_ring" "key_ring" {
  name = var.key_ring_name
  project = data.google_project.project-id.project_id
  location = var.region
}

resource "google_kms_crypto_key" "crypto_key" {
  name = var.vm_key_name
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = var.key_rotation_period

  lifecycle {
    prevent_destroy = false
  }

  version_template {
    algorithm = var.key_algorithm
  }
}

resource "google_kms_crypto_key_iam_binding" "key_iam_binding" {
  role = var.kms_admin_role
  crypto_key_id = google_kms_crypto_key.crypto_key.id
  members = [
    "serviceAccount:${google_service_account.webapp_instance_service_account.email}"
  ]
}

resource "google_project_iam_binding" "key_webapp_service_account_binding" {
  project = data.google_project.project-id.project_id
  role = var.kms_admin_role
  members = [
    "serviceAccount:${google_service_account.webapp_instance_service_account.email}"
  ]
}

resource "google_kms_crypto_key_iam_binding" "decrypters" {
  role = var.crypto_keydecrypter_role
  crypto_key_id = google_kms_crypto_key.crypto_key.id
  members = [
    "serviceAccount:${google_service_account.webapp_instance_service_account.email}"
  ]
}

resource "google_kms_crypto_key_iam_binding" "encrypters" {
  role = var.crypto_keyencrypter_role
  crypto_key_id = google_kms_crypto_key.crypto_key.id
  members = [
    "serviceAccount:${google_service_account.webapp_instance_service_account.email}"
  ]
}

resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.crypto_key.id
  role          = var.crypto_keyencrypterdecrypter_role
  members = [
    "serviceAccount:service-${data.google_project.project-id.number}@compute-system.iam.gserviceaccount.com",
  ]
}

########## sql keys

resource "google_kms_crypto_key" "sql_crypto_key" {
  name = var.sql_key_name
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = var.key_rotation_period

  lifecycle {
    prevent_destroy = false
  }

  version_template {
    algorithm = var.key_algorithm
  }
}
# resource "google_service_account" "gcp_sa_cloud_sql" {
#   account_id = data.google_project.project-id.project_id
#   display_name = "sql-admin-account"
# }

# resource "google_project_iam_binding" "sql_admin_binding" {
#   project = data.google_project.project-id.project_id
#   role = "roles/iam.serviceAccountAdmin"
#   members = [
#     "serviceAccount:${google_service_account.gcp_sa_cloud_sql.email}"
#   ]
# }
resource "google_kms_crypto_key_iam_binding" "db_crypto_key" {
  crypto_key_id = google_kms_crypto_key.sql_crypto_key.id
  role          = var.crypto_keyencrypterdecrypter_role
  members = [
    "serviceAccount:service-${data.google_project.project-id.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
  ]
}


### bucket keys

resource "google_kms_crypto_key" "bucket_crypto_key" {
  name = var.bucket_key_name
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = var.key_rotation_period

  lifecycle {
    prevent_destroy = false
  }

  version_template {
    algorithm = var.key_algorithm
  }
}

# resource "google_project_service_identity" "gcp_sa_cloud_sql" {
#   provider = google-beta
#   service  = "sqladmin.googleapis.com"
# }

resource "google_kms_crypto_key_iam_binding" "bucket_crypto_key" {
  crypto_key_id = google_kms_crypto_key.bucket_crypto_key.id
  role          = var.crypto_keyencrypterdecrypter_role
  members = [
    "serviceAccount:service-${data.google_project.project-id.number}@gs-project-accounts.iam.gserviceaccount.com",
  ]
}