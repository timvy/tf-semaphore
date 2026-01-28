terraform {
  required_providers {
    bitwarden = {
      source = "maxlaverse/bitwarden"
    }
    semaphoreui = {
      source = "CruGlobal/semaphoreui"
    }
  }
}

provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}

data "bitwarden_secret" "domain_home" {
  key = "domain_home"
}

data "bitwarden_secret" "domain_tailscale" {
  key = "domain_tailscale"
}

data "bitwarden_secret" "semaphore_api_admin" {
  key = "semaphore_api_admin"
}

provider "semaphoreui" {
}
