provider "google" {
    project = var.project_name
    region = var.region
}

resource "random_string" "vpc_suffix" {
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

resource "google_compute_subnetwork" "webapp_subnet" {
    name = var.webapp_subnet
    ip_cidr_range = var.ip_cidr_range_webapp
    network = google_compute_network.private_vpc.id
    region = var.region
}

resource "google_compute_subnetwork" "db_subnet" {
    name = var.db_subnet
    ip_cidr_range = var.ip_cidr_range_db
    network = google_compute_network.private_vpc.id
    region = var.region
}

resource "google_compute_route" "webapp_subnet_route" {
    name = var.webapp_subnet_route
    network = google_compute_network.private_vpc.id
    dest_range = var.webapp_destination
    next_hop_gateway = var.next_hop_gateway
}

resource "google_compute_firewall" "private_vpc_firewall" {
    name = "webapp-http-firewall"
    network = google_compute_network.private_vpc.name

    allow {
      protocol = "tcp"
      ports = ["8080"]
    }
    source_tags = []
    target_tags = ["webapp-instance"]
}

resource "google_compute_instance" "webapp_instance" {
    name = var.instance_name
    machine_type = var.instance_type
    zone = var.zone

    tags = ["webapp-instance"]
    boot_disk {
        initialize_params {
          image = var.instance_image
          size = 100
          type = "pd-balanced"
        }
    }

    network_interface {
        network = google_compute_network.private_vpc.name
        subnetwork = google_compute_subnetwork.webapp_subnet.name
        access_config {
        network_tier = "PREMIUM"
      }
    }
}
