locals {
  bitwarden_secrets = [
    "bitwarden_auth_token",
    "bitwarden_client_id",
    "bitwarden_client_secret",
    "bitwarden_password",
    "minio_s3_url",
    "minio_tf_access_key",
    "minio_tf_secret",
    "proxmox_api_password",
    "proxmox_api_url",
    "proxmox_api_user",
    "ssh_semaphore_github",
    "ssh_semaphore_homelab",
    "splunk_url",
    "splunk_api_password",
    "splunk_api_user",
    "tailscale_api_key",
    "tailscale_tailnet"
  ]
  project_keys_ssh = {
    semaphore_github = {
      private_key = data.bitwarden_secret.secret["ssh_semaphore_github"].value
    }
    semaphore_homelab = {
      private_key = data.bitwarden_secret.secret["ssh_semaphore_homelab"].value
      login        = "ansible"
    }
  }
  repositories = {
    ansible_collection_homelab = {
      url = "git@github.com:timvy/ansible_collection_homelab.git"
    }
    ansible_inventory_homelab = {
      url = "git@github.com:timvy/ansible_inventory_homelab.git"
    }
    terraform_homelab = {
      url = "git@github.com:timvy/terraform_homelab.git"
    },
  }
  inventories = {
    ansible_inventory_proxmox = {
      name = "Proxmox"
      file = {
        path          = "inventory/proxmox.yml"
        repository_id = semaphoreui_project_repository.repositories["ansible_inventory_homelab"].id
      }
    }
    terraform_docker = {
      name = "Docker"
      terraform_workspace = {
        workspace = "docker"
      }
    }
    terraform_certs = {
      name = "Certificates"
      terraform_workspace = {
        workspace = "certs"
      }
    }
    terraform_lxc = {
      name = "LXC"
      terraform_workspace = {
        workspace = "lxc"
      }
    }
  }
  environments = {
    ansible_proxmox = {
      name        = "Proxmox Inventory"
      variables   = {}
      environment = {}
      secrets = [{
        name  = "proxmox_host"
        value = "pve-hpe.${data.bitwarden_secret.domain_tailscale.value}"
        type  = "var"
        }, {
        name  = "PROXMOX_PASSWORD"
        value = data.bitwarden_secret.secret["proxmox_api_password"].value
        type  = "env"
        }, {
        name  = "PROXMOX_USER"
        value = data.bitwarden_secret.secret["proxmox_api_user"].value
        type  = "env"
        }, {
        name  = "PROXMOX_URL"
        value = "https://pve-hpe.${data.bitwarden_secret.domain_tailscale.value}"
        type  = "env"
        }
      ]
    }
    terraform_homelab = {
      name        = "Terraform Homelab"
      variables   = {}
      environment = {}
      secrets = [{
        name  = "AWS_ACCESS_KEY_ID"
        value = data.bitwarden_secret.secret["minio_tf_access_key"].value
        type  = "env"
        }, {
        name  = "AWS_SECRET_ACCESS_KEY"
        value = data.bitwarden_secret.secret["minio_tf_secret"].value
        type  = "env"
        }, {
        name  = "AWS_ENDPOINT_URL_S3"
        value = data.bitwarden_secret.secret["minio_s3_url"].value
        type  = "env"
        }, {
        name  = "BW_CLIENTID"
        value = data.bitwarden_secret.secret["bitwarden_client_id"].value
        type  = "env"
        }, {
        name  = "BW_CLIENTSECRET"
        value = data.bitwarden_secret.secret["bitwarden_client_secret"].value
        type  = "env"
        }, {
        name  = "BW_PASSWORD"
        value = data.bitwarden_secret.secret["bitwarden_password"].value
        type  = "env"
        }, {
        name  = "TAILSCALE_API_KEY"
        value = data.bitwarden_secret.secret["tailscale_api_key"].value
        type  = "env"
        }, {
        name  = "TAILSCALE_TAILNET"
        value = data.bitwarden_secret.secret["tailscale_tailnet"].value
        type  = "env"
        }
      ]
    }
    terraform_homelab_bw = {
      name        = "Terraform Homelab with Bitwarden Secrets"
      variables   = {}
      environment = {}
      secrets = [{
        name  = "AWS_ACCESS_KEY_ID"
        value = data.bitwarden_secret.secret["minio_tf_access_key"].value
        type  = "env"
        }, {
        name  = "AWS_SECRET_ACCESS_KEY"
        value = data.bitwarden_secret.secret["minio_tf_secret"].value
        type  = "env"
        }, {
        name  = "AWS_ENDPOINT_URL_S3"
        value = data.bitwarden_secret.secret["minio_s3_url"].value
        type  = "env"
        }, {
        name  = "BWS_ACCESS_TOKEN"
        value = data.bitwarden_secret.secret["bitwarden_auth_token"].value
        type  = "env"
        }, {
        name  = "PM_USER"
        value = data.bitwarden_secret.secret["proxmox_api_user"].value
        type  = "env"
        }, {
        name  = "PM_PASS"
        value = data.bitwarden_secret.secret["proxmox_api_password"].value
        type  = "env"
        }, {
        name  = "PM_API_URL"
        value = data.bitwarden_secret.secret["proxmox_api_url"].value
        type  = "env"
        }, {
        name  = "SPLUNK_URL"
        value = data.bitwarden_secret.secret["splunk_url"].value
        type  = "env"
        }, {
        name  = "SPLUNK_USERNAME"
        value = data.bitwarden_secret.secret["splunk_api_user"].value
        type  = "env"
        }, {
        name  = "SPLUNK_PASSWORD"
        value = data.bitwarden_secret.secret["splunk_api_password"].value
        type  = "env"
        }, {
        name  = "TAILSCALE_API_KEY"
        value = data.bitwarden_secret.secret["tailscale_api_key"].value
        type  = "env"
        }, {
        name  = "TAILSCALE_TAILNET"
        value = data.bitwarden_secret.secret["tailscale_tailnet"].value
        type  = "env"
        }
      ]
    }
  }
  templates = {
    ans_os_update = {
      name        = "ans_os_update"
      playbook    = "playbooks/os_update.yml"
      repository  = "ansible_collection_homelab"
      inventory   = "ansible_inventory_proxmox"
      environment = "ansible_proxmox"
    }
    terraform_docker = {
      name        = "terraform_docker"
      description = "Terraform tasks for the docker homelab project"
      app         = "tofu"
      playbook    = "docker"
      repository  = "terraform_homelab"
      inventory   = "terraform_docker"
      environment = "terraform_homelab"
      arguments = [
        "-parallelism=1"
      ]
    }
    terraform_certificates = {
      name        = "terraform_certificates"
      description = "Terraform tasks for the certificates homelab project"
      app         = "tofu"
      playbook    = "certs"
      repository  = "terraform_homelab"
      inventory   = "terraform_certs"
      environment = "terraform_homelab_bw"
      arguments = [
        "-parallelism=1"
      ]
      schedules = {
        tf_certs_weekly = {
          cron_format = "0 0 * * 0"
        }
      }
    }
    terraform_LXC = {
      name        = "terraform_lxc"
      description = "Terraform tasks for the LXC homelab project"
      app         = "tofu"
      playbook    = "lxc"
      repository  = "terraform_homelab"
      inventory   = "terraform_lxc"
      environment = "terraform_homelab_bw"
      arguments = [
        "-parallelism=1"
      ]
    }
  }

}
