terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  team_zone     = (var.team_id - 1) % 3
  jumphost_zone = coalesce(var.jumphost_zone, data.google_compute_zones.available.names[local.team_zone])
  primary_zone  = coalesce(var.primary_zone, data.google_compute_zones.available.names[local.team_zone])
  subnet_cidr   = "10.0.${var.team_id}.0/24"
}

data "google_compute_zones" "available" {
  region = var.region
}

data "google_compute_network" "team_vpc" {
  name = "team${var.team_id}-vpc"
}

resource "google_compute_subnetwork" "team" {
  name                     = "team${var.team_id}-subnet"
  ip_cidr_range            = local.subnet_cidr
  region                   = var.region
  network                  = data.google_compute_network.team_vpc.id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_address" "jumphost" {
  name   = "team${var.team_id}-jumphost-ip"
  region = var.region
}

resource "google_compute_route" "internet_via_jumphost" {
  name              = "team${var.team_id}-internet-via-jumphost"
  network           = data.google_compute_network.team_vpc.id
  dest_range        = "0.0.0.0/0"
  priority          = 800
  next_hop_instance = google_compute_instance.jumphost.self_link
  tags              = ["no-external-ip"]
}

resource "google_compute_route" "tailnet_via_jumphost" {
  name              = "team${var.team_id}-tailnet-via-jumphost"
  network           = data.google_compute_network.team_vpc.id
  dest_range        = "100.64.0.0/10"
  priority          = 800
  next_hop_instance = google_compute_instance.jumphost.self_link
  tags              = ["no-external-ip"]
}

resource "google_compute_resource_policy" "daily_schedule" {
  name   = "team${var.team_id}-daily-schedule"
  region = var.region

  instance_schedule_policy {
    time_zone = "Europe/Stockholm"
    vm_start_schedule {
      schedule = "0 8 * * *"
    }
    vm_stop_schedule {
      schedule = "0 0 * * *"
    }
  }
}

resource "google_compute_instance" "jumphost" {
  #checkov:skip=CKV_GCP_38:Labbprojektet använder Google-hanterad diskkryptering; egna CSEK-nycklar ingår inte i miljön.
  #checkov:skip=CKV_GCP_40:Jumphosten behöver en fast publik IP för SSH och Headscale via instructor-proxy.
  #checkov:skip=CKV_GCP_36:IP forwarding krävs eftersom jumphosten är router och NAT-gateway för primary och Tailnet.
  name         = "team${var.team_id}-jumphost"
  machine_type = "e2-micro"
  zone         = local.jumphost_zone

  allow_stopping_for_update = true
  can_ip_forward            = true

  tags = ["jumphost"]


  service_account {
    email  = "team${var.team_id}-jumphost@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  resource_policies = [google_compute_resource_policy.daily_schedule.id]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-13"
      size  = 20
    }
  }

  # Secure Boot kan inte aktiveras med labbens image. Kärnan underkänns av
  # shim: "prohibited by secure boot policy" och "bad shim signature".
  # Maskinen blir då stående i GRUB-menyn och når aldrig OS, medan instansen
  # ändå rapporterar RUNNING. Slå inte på igen utan en signerad kärna.
  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.team.id
    network_ip = cidrhost(local.subnet_cidr, 2)
    access_config {
      nat_ip = google_compute_address.jumphost.address
    }
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = true
    startup-script         = <<-EOT
      #!/bin/bash
      set -e

      if ! swapon --show | grep -q "/swapfile"; then
        fallocate -l 1G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
      fi

      echo 'vm.swappiness=20' > /etc/sysctl.d/01-swappiness.conf
      echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-ip-forward.conf
      sysctl --system

      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y dnsmasq

      cat > /etc/dnsmasq.d/tailscale-gcp-dns.conf <<'DNSMASQ'
      interface=tailscale0
      bind-dynamic
      server=169.254.169.254
      DNSMASQ

      systemctl restart dnsmasq

      DEFAULT_IF=$(ip ro sh default | awk '/default/ {print $5}')
      iptables -t nat -A POSTROUTING -o "$DEFAULT_IF" -s "${local.subnet_cidr}" -j MASQUERADE
      iptables -t nat -A POSTROUTING -o "$DEFAULT_IF" -d 10.0.0.2/32 -j MASQUERADE
    EOT
  }
}

resource "google_compute_instance" "primary" {
  #checkov:skip=CKV_GCP_38:Labbprojektet använder Google-hanterad diskkryptering; egna CSEK-nycklar ingår inte i miljön.
  name         = "team${var.team_id}-primary"
  machine_type = "e2-small"
  zone         = local.primary_zone

  allow_stopping_for_update = true

  tags = ["primary", "no-external-ip"]

  resource_policies = [google_compute_resource_policy.daily_schedule.id]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-13"
      size  = 20
    }
  }

  # Secure Boot lämnas av eftersom labbimagen saknar godkänd signerad kärna.
  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.team.id
    network_ip = cidrhost(local.subnet_cidr, 3)
  }

  metadata = {
    # Behåll metadata-nycklar under övergången. De tas bort först när
    # samtliga OS Login-användare har verifierat åtkomst till primary.
    enable-oslogin         = "TRUE"
    ssh-keys               = join("\n", [for user in var.ssh_users : "${user.username}:${user.public_key}"])
    block-project-ssh-keys = true
    startup-script         = <<-EOT
       #!/bin/bash
       set -e

       if ! swapon --show | grep -q "/swapfile"; then
         fallocate -l 1G /swapfile
         chmod 600 /swapfile
         mkswap /swapfile
         swapon /swapfile
         echo '/swapfile none swap sw 0 0' >> /etc/fstab
       fi

       echo 'vm.swappiness=20' > /etc/sysctl.d/01-swappiness.conf
       sysctl --system
     EOT
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "team${var.team_id}-allow-ssh"
  network = data.google_compute_network.team_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["jumphost", "primary"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "team${var.team_id}-allow-iap-ssh"
  network = data.google_compute_network.team_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["jumphost", "primary"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "team${var.team_id}-allow-internal"
  network = data.google_compute_network.team_vpc.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [local.subnet_cidr, "100.64.0.0/10"]
  target_tags   = ["jumphost", "primary"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_instructor" {
  name    = "team${var.team_id}-allow-instructor"
  network = data.google_compute_network.team_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["10.0.0.2/32"]
  target_tags   = ["jumphost"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
# Tilldela administratörsåtkomst endast till användare som behöver sudo.
resource "google_compute_instance_iam_member" "jumphost_os_admin_login" {
  for_each      = toset(var.os_admin_users)
  instance_name = google_compute_instance.jumphost.name
  zone          = google_compute_instance.jumphost.zone
  role          = "roles/compute.osAdminLogin"
  member        = "user:${each.value}"
}

# Övriga teammedlemmar kan logga in men saknar sudo-rättigheter.
resource "google_compute_instance_iam_member" "jumphost_os_login" {
  for_each      = toset(var.os_login_users)
  instance_name = google_compute_instance.jumphost.name
  zone          = google_compute_instance.jumphost.zone
  role          = "roles/compute.osLogin"
  member        = "user:${each.value}"
}

# Primary använder samma IAM-styrda SSH-åtkomst som jumphosten.
# Metadata-nycklarna finns kvar tillfälligt tills inloggning har verifierats.
resource "google_compute_instance_iam_member" "primary_os_admin_login" {
  for_each      = toset(var.os_admin_users)
  instance_name = google_compute_instance.primary.name
  zone          = google_compute_instance.primary.zone
  role          = "roles/compute.osAdminLogin"
  member        = "user:${each.value}"
}

resource "google_compute_instance_iam_member" "primary_os_login" {
  for_each      = toset(var.os_login_users)
  instance_name = google_compute_instance.primary.name
  zone          = google_compute_instance.primary.zone
  role          = "roles/compute.osLogin"
  member        = "user:${each.value}"
}
