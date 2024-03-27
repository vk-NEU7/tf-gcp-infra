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
    target_tags = var.webapp_firewall_target_tags
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
    depends_on = [ google_service_networking_connection.networking_connection ]
    
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

resource "google_compute_instance" "webapp_instance" {
    name = var.webapp_instance_name
    machine_type = var.webapp_instance_type
    zone = var.zone

    tags = var.webapp_instance_tags
    allow_stopping_for_update = true

    depends_on = [google_service_account.webapp_instance_service_account, 
    google_project_iam_binding.webapp_logging_binding, 
    google_project_iam_binding.webapp_monitoring_binding,
    google_pubsub_subscription_iam_binding.webapp_pubsub_binding]
    service_account {
      email = google_service_account.webapp_instance_service_account.email
      scopes = var.webapp_instance_scopes
    }
    boot_disk {
        initialize_params {
          image = var.webapp_instance_image
          size = var.webapp_instance_size
          type = var.webapp_instance_bootdisk_type
        }
    }

    network_interface {
        network = google_compute_network.private_vpc.name
        subnetwork = google_compute_subnetwork.webapp_subnet.name
        access_config {
        network_tier = var.webapp_instance_networktier
      }
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

data "google_dns_managed_zone" "webapp_zone" {
  name = var.dns_zone_webapp
}

resource "google_dns_record_set" "zone_instance" {
  name = data.google_dns_managed_zone.webapp_zone.dns_name
  managed_zone = data.google_dns_managed_zone.webapp_zone.name
  type = var.dns_record_webapp_A
  ttl = var.dns_record_webapp_A_ttl
  rrdatas = [
    google_compute_instance.webapp_instance.network_interface[0].access_config[0].nat_ip
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