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

resource "google_compute_network" "private_vpc_assn3" {
    name = "vpc-${random_string.vpc_suffix.result}"
    auto_create_subnetworks = var.auto_create_subnets
    routing_mode = var.routing_mode_RGL
}

resource "google_compute_subnetwork" "webapp_subnet" {
    name = var.webapp_subnet
    ip_cidr_range = var.ip_cidr_range_webapp
    network = google_compute_network.private_vpc_assn3.id
    region = var.region
}

resource "google_compute_subnetwork" "db_subnet" {
    name = var.db_subnet
    ip_cidr_range = var.ip_cidr_range_db
    network = google_compute_network.private_vpc_assn3.id
    region = var.region
}

resource "google_compute_route" "webapp_subnet_route" {
    name = var.webapp_subnet_route
    network = google_compute_subnetwork.webapp_subnet.network
    dest_range = var.webapp_destination
    priority = 1000
    next_hop_gateway = "default-internet-gateway"
}