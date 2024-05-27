# You must complete the following scenerio.

# A European gaming company is moving to GCP.  It has the following requirements in it's first stage migration to the Cloud:

# A) You must choose a region in Europe to host it's prototype gaming information.  This page must only be on a RFC 1918 Private 10 net and can't be accessible from the Internet.
# B) The Americas must have 2 regions and both must be RFC 1918 172.16 based subnets.  They can peer with HQ in order to view the homepage however, they can only view the page on port 80.
# C) Asia Pacific region must be choosen and it must be a RFC 1918 192.168 based subnet.  This subnet can only VPN into HQ.  Additionally, only port 3389 is open to Asia. No 80, no 22.

# Deliverables.
# 1) Complete Terraform for the entire solution.
# 2) Git Push of the solution to your GitHub.
# 3) Screenshots showing how the HQ homepage was accessed from both the Americas and Asia Pacific. 

#   I WOULD HAVE TO ACTIVATE MY GCP ACCOUNT (WHICH WILL ALLOW ME TO GET BILLED AFTER FREE PLAN TIME OR VALUE RUNS OUT) TO CREATE A WINDOWS MACHINE FOR ASIA TO TRULY COMPLETE THIS TASK.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.27.0"
    }
  }
}


#EUROPE-
provider "google" {
  project     = "elemental-apex-420520"
  credentials = "elemental-apex-420520-8d3f13306920.json"
  region      = "europe-west1"
  zone        = "europe-west1-d"
}

# **-INSTEAD OF THESE THREE VPC's, TRY TO MAKE ONE TO CONTROL THE FOUR INSTANCES (CAN'T GET THIS TO WORK FOR PEERING SECTION...)-**
resource "google_compute_network" "europe_network" {
  name                    = "europe-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "europe_subnet" {
  name                     = "europe-subnet"
  ip_cidr_range            = "10.0.0.0/24"
  network                  = google_compute_network.europe_network.id
  region                   = "europe-west1"
  private_ip_google_access = true
}

resource "google_compute_instance" "europe_instance" {
  name         = "europe-instance"
  machine_type = "e2-medium"
  zone         = "europe-west1-d"
  depends_on   = [google_compute_subnetwork.europe_subnet]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.europe_network.id
    subnetwork = google_compute_subnetwork.europe_subnet.id
    access_config {
      // Ephemeral IP
    }
  }

  tags = ["europe-http-server"]

  metadata_startup_script = "echo 'Hello, World!' > index.html && python3 -m http.server 80"

  # ??? #
  #   service_account {
  #     scopes = ["task3"]
  #   }
  # ??? #
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.europe_network.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["10.0.0.0/24", "172.16.10.0/24", "172.16.100.0/24", "192.168.0.0/24"]
  target_tags   = ["europe-http-server", "america-http-server", "asia-rdp-server"]
}


# AMERICAS-
resource "google_compute_network" "americas_network" {
  name                    = "americas-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "americas_subnet1" {
  name                     = "americas-subnet1"
  ip_cidr_range            = "172.16.10.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.americas_network.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "americas_subnet2" {
  name                     = "americas-subnet2"
  ip_cidr_range            = "172.16.100.0/24"
  region                   = "us-west1"
  network                  = google_compute_network.americas_network.id
  private_ip_google_access = true
}

resource "google_compute_instance" "americas_instance1" {
  name         = "americas-instance1"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  depends_on   = [google_compute_subnetwork.americas_subnet1]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.americas_network.id
    subnetwork = google_compute_subnetwork.americas_subnet1.id
    access_config {
      // Ephemeral IP
    }
  }

  tags = ["america-http-server", "iap-ssh-allowed"]
}

resource "google_compute_instance" "americas_instance2" {
  name         = "americas-instance2"
  machine_type = "e2-micro"
  zone         = "us-west1-a"
  depends_on   = [google_compute_subnetwork.americas_subnet2]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.americas_network.id
    subnetwork = google_compute_subnetwork.americas_subnet2.id
    access_config {
      // Ephemeral IP
    }
  }

  tags = ["america-http-server", "iap-ssh-allowed"]
}

resource "google_compute_firewall" "americas_allow_http" {
  name    = "americas-allow-http"
  network = google_compute_network.americas_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["10.0.0.0/24", "35.235.240.0/20" /*THIS IP ADDRESS IS SPECIFIC TO GOOGLE AND NECESSARY TO SSH INTO THIS INSTANCE*/]
  target_tags   = ["america-http-server", "iap-ssh-allowed"]
}


# ASIA-
resource "google_compute_network" "asia_network" {
  name                    = "asia-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "asia_subnet" {
  name                     = "asia-subnet"
  ip_cidr_range            = "192.168.0.0/24"
  region                   = "asia-east1"
  network                  = google_compute_network.asia_network.id
  private_ip_google_access = true
}

resource "google_compute_instance" "asia_instance" {
  name         = "asia-instance"
  machine_type = "e2-micro"
  zone         = "asia-east1-a"
  depends_on   = [google_compute_subnetwork.asia_subnet]

  boot_disk {
    initialize_params {
      #   image = "projects/windows-cloud/global/images/windows-server-2022-dc-v20240415"
      image = "debian-cloud/debian-11"
    }
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.asia_network.id
    subnetwork = google_compute_subnetwork.asia_subnet.id
    access_config {
      // Ephemeral IP
    }
  }

  tags = ["asia-rdp-server"]
}

resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"
  network = google_compute_network.asia_network.id

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["10.0.0.0/24"]
  target_tags   = ["asia-rdp-server"]
}


#PEERING-
resource "google_compute_network_peering" "europe_americas_peering" {
  name         = "europe-americas-peering"
  network      = google_compute_network.europe_network.id
  peer_network = google_compute_network.americas_network.id
  #   auto_create_routes = false
}

resource "google_compute_network_peering" "americas_europe_peering" {
  name         = "americas-europe-peering"
  network      = google_compute_network.americas_network.id
  peer_network = google_compute_network.europe_network.id
  #   auto_create_routes = false
}


# VPN GATEWAY AND TUNNELING-
# EUROPE GATEWAY
resource "google_compute_vpn_gateway" "europe_vpn_gateway" {
  name    = "europe-vpn-gateway"
  network = google_compute_network.europe_network.id
  region  = "europe-west1"
}

# ASIA GATEWAY
resource "google_compute_vpn_gateway" "asia_vpn_gateway" {
  name    = "asia-vpn-gateway"
  network = google_compute_network.asia_network.id
  region  = "asia-east1"
}

# EXTERNAL STATIC IP ADDRESS FOR VPN GATEWAYS
resource "google_compute_address" "europe_vpn_ip" {
  name   = "europe-vpn-ip"
  region = "europe-west1"
}

resource "google_compute_address" "asia_vpn_ip" {
  name   = "asia-vpn-ip"
  region = "asia-east1"
}


# VPN TUNNEL FROM ASIA TO EUROPE
# resource "google_secret_manager_secret_version" "vpn_secret" {
#   secret = "vpn-shared-secret"
#   #   ****-
#   secret_data = "vpn-shared-secret" # I WAS GETTING AN ERROR WITHOUT THIS PARAMETER SO I MADE IT THE SAME AS "secret"
#   #   ****-
#   # version = "latest" #**-**
# }

resource "google_compute_vpn_tunnel" "asia_to_europe_tunnel" {
  name               = "asia-to-europe-tunnel"
  region             = "asia-east1"
  target_vpn_gateway = google_compute_vpn_gateway.asia_vpn_gateway.id
  peer_ip            = google_compute_address.europe_vpn_ip.address
  #   shared_secret      = data.google_secret_manager_secret_version.vpn_secret.secret_data #**-**
  shared_secret = "secret-"
  ike_version   = 2

  local_traffic_selector  = ["192.168.0.0/24"]
  remote_traffic_selector = ["10.0.0.0/24"]

  depends_on = [
    google_compute_forwarding_rule.asia_esp,
    google_compute_forwarding_rule.asia_udp500,
    google_compute_forwarding_rule.asia_udp4500,
  ]
}

# ROUTE FOR ASIA TO EUROPE
resource "google_compute_route" "asia_to_europe_route" {
  name                = "asia-to-europe-route"
  network             = google_compute_network.asia_network.id
  dest_range          = "10.0.0.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.asia_to_europe_tunnel.id
  priority            = 1000
}


# FORWARDING RULES FOR THE ASIA VPN
resource "google_compute_forwarding_rule" "asia_esp" {
  name        = "asia-esp"
  region      = "asia-east1"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.asia_vpn_ip.address
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "asia_udp500" {
  name        = "asia-udp500"
  region      = "asia-east1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.asia_vpn_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "asia_udp4500" {
  name        = "asia-udp4500"
  region      = "asia-east1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.asia_vpn_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
}

#REVERSE VPN TUNNEL FROM EUROPE TO ASIA
resource "google_compute_vpn_tunnel" "europe_to_asia_tunnel" {
  name               = "europe-to-asia-tunnel"
  region             = "europe-west1"
  target_vpn_gateway = google_compute_vpn_gateway.europe_vpn_gateway.id
  peer_ip            = google_compute_address.asia_vpn_ip.address
  #   shared_secret      = data.google_secret_manager_secret_version.vpn_secret.secret_data #**-**
  shared_secret = "secret-"
  ike_version   = 2

  local_traffic_selector  = ["10.0.0.0/24"]
  remote_traffic_selector = ["192.168.0.0/24"]

  depends_on = [
    google_compute_forwarding_rule.europe_esp,
    google_compute_forwarding_rule.europe_udp500,
    google_compute_forwarding_rule.europe_udp4500,
  ]
}

# ROUTE FOR EUROPE TO ASIA
resource "google_compute_route" "europe_to_asia_route" {
  depends_on          = [google_compute_vpn_tunnel.europe_to_asia_tunnel]
  name                = "europe-to-asia-route"
  network             = google_compute_network.europe_network.id
  dest_range          = "192.168.0.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.europe_to_asia_tunnel.id
}

# FORWARDING RULES FOR EUROPE VPN
resource "google_compute_forwarding_rule" "europe_esp" {
  name        = "europe-esp"
  region      = "europe-west1"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.europe_vpn_ip.address
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "europe_udp500" {
  name        = "europe-udp500"
  region      = "europe-west1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.europe_vpn_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "europe_udp4500" {
  name        = "europe-udp4500"
  region      = "europe-west1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.europe_vpn_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}
