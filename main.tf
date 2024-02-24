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

resource "google_compute_network" "private_vpc" {
    name = var.vpc_name
    auto_create_subnetworks = var.auto_create_subnets
    routing_mode = var.routing_mode_RGL
    delete_default_routes_on_create = var.delete_default_route
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_vpc.id
}

resource "google_service_networking_connection" "networking_connection" {
  network                 = google_compute_network.private_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
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

# resource "google_compute_firewall" "private_vpc_firewall1" {
#     name = var.webapp_firewall_ssh
#     network = google_compute_network.private_vpc.name

#     deny {
#       protocol = var.webapp_firewall_protocol
#       ports = var.webapp_firewall_protocol_deny_ports
#     }

#     source_tags = var.webapp_firewall_source_tags
#     target_tags = var.webapp_firewall_target_tags
# }

resource "google_compute_firewall" "private_vpc_firewall_blockdbtraffic" {
    name = var.db_firewall_name
    network = google_compute_network.private_vpc.name

    allow {
      protocol = "tcp"
      ports = ["5432"]
    }
    source_ranges = ["10.1.0.0/24"]
}

resource "google_sql_database" "app_db" {
    name = "app_db"
    instance = google_sql_database_instance.db_instance.name  
    deletion_policy = "delete"
}

resource "google_sql_database_instance" "db_instance" {
    name = "new-instance"
    region = var.region
    database_version = "POSTGRES_10"
    depends_on = [ google_service_networking_connection.networking_connection ]
    
    settings {
      tier = "db-f1-micro"
      disk_type = "pd-ssd"
      disk_size = 100

      ip_configuration {
        ipv4_enabled = false
        private_network = google_compute_network.private_vpc.id
      }
      availability_type = "REGIONAL"
    }
  
  deletion_protection = false
}

resource "google_sql_user" "user_details" {
    instance = google_sql_database_instance.db_instance.name
    name = var.db_user
    password = var.db_password
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
    touch /tmp/.env
    sudo echo "DB=${google_sql_database_instance.db_instance.private_ip_address}" >> /tmp/.env
    sudo echo "DB_USER=${var.db_user}" >> /tmp/.env
    sudo echo "DB_PASSWORD=${var.db_password}" >> /tmp/.env
    # sudo mv /tmp/.env /opt/webapp/
    # sudo chmod 750 /opt/webapp/.env
    # sudo chown csye6225:csye6225 /opt/webapp/.env
    
    EOT
}
