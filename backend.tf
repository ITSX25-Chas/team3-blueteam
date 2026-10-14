terraform {
  backend "gcs" {
    bucket = "itsx25-comerit-team3-tfstate"
    prefix = "terraform/state"
  }
}
