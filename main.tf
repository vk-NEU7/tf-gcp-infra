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

resource "google_compute_instance" "webapp_instance" {
    name = var.webapp_instance_name
    machine_type = var.webapp_instance_type
    zone = var.zone

    tags = var.webapp_instance_tags
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
    EOT
}
