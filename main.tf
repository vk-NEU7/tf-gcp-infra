variable "vpc_count" {}
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
    count = var.vpc_count
    name = var.vpc_name[count.index]
    auto_create_subnetworks = var.auto_create_subnets
    routing_mode = var.routing_mode_RGL
    delete_default_routes_on_create = var.delete_default_route
}

resource "google_compute_subnetwork" "webapp_subnet" {
    count = var.vpc_count
    name = "webapp-${count.index + 1}"
    ip_cidr_range = var.ip_cidr_range_webapp
    network = google_compute_network.private_vpc_assn3[count.index].id
    region = var.region
}

resource "google_compute_subnetwork" "db_subnet" {
    count = var.vpc_count
    name = "db-${count.index + 1}"
    ip_cidr_range = var.ip_cidr_range_db
    network = google_compute_network.private_vpc_assn3[count.index].id
    region = var.region
}

resource "google_compute_route" "webapp_subnet_route" {
    count = var.vpc_count
    name = "webapp-route-${count.index + 1}"
    network = google_compute_network.private_vpc_assn3[count.index].id
    dest_range = var.webapp_destination
    next_hop_gateway = var.next_hop_gateway
}