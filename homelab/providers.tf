terraform {
  required_providers {
    bitwarden = {
      source = "maxlaverse/bitwarden"
    }
    semaphoreui = {
      source = "CruGlobal/semaphoreui"
    }
  }
  backend "s3" {
    bucket                      = "tofu-backend"
    key                         = "homelab/semaphore/terraform.tfstate"
    region                      = "main" # this is required, but will be skipped!
    skip_credentials_validation = true   # this will skip AWS related validation
    skip_metadata_api_check     = true
    skip_region_validation      = true
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
  hostname  = "lxc-semaphore.${data.bitwarden_secret.domain_tailscale.value}"
  port      = 443
  api_token = data.bitwarden_secret.semaphore_api_admin.value
}
