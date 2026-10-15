terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    bucket = "team3-tfstate-87e75501"
    prefix = "terraform/bootstrap-state"
  }
}

provider "google" {
  project = var.project_id
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "terraform_state" {
  name     = "team${var.team_id}-tfstate-${random_id.bucket_suffix.hex}"
  location = "EU"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  logging {
    log_bucket        = google_storage_bucket.access_logs.name
    log_object_prefix = "terraform-state"
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Loggbucket för åtkomstloggar på state-bucketen. Samma slumpsuffix som
# state-bucketen, eftersom bucketnamn är globalt unika i hela GCP.
resource "google_storage_bucket" "access_logs" {
  #checkov:skip=CKV_GCP_62:Den här bucketen är själv mottagare för state-bucketens åtkomstloggar; att logga till sig själv stöds inte.
  name                        = "team${var.team_id}-storage-logs-${random_id.bucket_suffix.hex}"
  location                    = "EU"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# Utan den här bindningen levereras inga loggar alls.
# cloud-storage-analytics@google.com är Googles egen loggtjänst, och den
# ska bara ha skrivrätt på loggbucketen - aldrig på state-bucketen.
resource "google_storage_bucket_iam_member" "access_logs_writer" {
  bucket = google_storage_bucket.access_logs.name
  role   = "roles/storage.objectCreator"
  member = "group:cloud-storage-analytics@google.com"
}

resource "google_service_account" "cicd" {
  account_id   = "team${var.team_id}-cicd"
  display_name = "CI/CD Pipeline Service Account"
}

# CI/CD-kontot behover tre saker: hantera compute-resurser, agera som
# jumphostens service account, och lasa och skriva state i sin egen bucket.
# roles/editor gav rattigheter i hela det delade projektet.
resource "google_project_iam_member" "cicd_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

resource "google_service_account_iam_member" "cicd_act_as_jumphost" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/team${var.team_id}-jumphost@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cicd.email}"
}

data "google_iam_policy" "terraform_state" {
  # Behåll projektägarens nödåtkomst, men ta bort de automatiska
  # projectEditor/projectViewer-bindningarna från den delade bucketens policy.
  binding {
    role    = "roles/storage.legacyBucketOwner"
    members = ["projectOwner:${var.project_id}"]
  }

  binding {
    role    = "roles/storage.legacyObjectOwner"
    members = ["projectOwner:${var.project_id}"]
  }

  binding {
    role = "roles/storage.objectAdmin"
    members = concat(
      ["serviceAccount:${google_service_account.cicd.email}"],
      [for email in var.state_admin_users : "user:${email}"]
    )
  }
}

resource "google_storage_bucket_iam_policy" "terraform_state" {
  bucket      = google_storage_bucket.terraform_state.name
  policy_data = data.google_iam_policy.terraform_state.policy_data
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "team${var.team_id}-github-pool"
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  #checkov:skip=CKV_GCP_125:Trust begränsas med CEL till exakt repository och refs/heads/main nedan.
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "team${var.team_id}-github-provider"
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Endast workflow-körningar från repots main-branch får växla till
  # CI/CD-kontot. Det begränsar skadan om en annan branch innehåller ett
  # manipulerat workflow.
  attribute_condition = "assertion.repository == '${var.github_repo}' && assertion.ref == 'refs/heads/main'"
}

resource "google_service_account_iam_member" "cicd_workload_identity" {
  service_account_id = google_service_account.cicd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# Tunnelrollen (roles/iap.tunnelResourceAccessor) hanteras inte i kod ännu.
# Instansnivå kräver roles/iap.policyAdmin, som vi inte har - försöket gav 403
# på iap.tunnelInstances.getIamPolicy. Projektnivå skulle fungera men rör IAM
# i det delade projektet, utanför team3:s egna resurser. Avvaktar besked från
# instruktören. Se motsvarande issue.
