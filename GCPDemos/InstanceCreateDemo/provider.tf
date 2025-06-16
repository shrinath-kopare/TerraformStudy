terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.40.0"
    }
  }
}

provider "google" {
  project     = "${PROJECT_NAME}"
  region      = "us-central1"
  zone        = "us-central1-a"
  credentials = "./gcpkey1.json"
}