# Common secrets that can be reused across environments
locals {
  # Common AWS/Minio secrets
  aws_secrets = [
    {
      name  = "AWS_ACCESS_KEY_ID"
      value = data.bitwarden_secret.secret["minio_tf_access_key"].value
      type  = "env"
    },
    {
      name  = "AWS_SECRET_ACCESS_KEY"
      value = data.bitwarden_secret.secret["minio_tf_secret"].value
      type  = "env"
    },
    {
      name  = "AWS_ENDPOINT_URL_S3"
      value = data.bitwarden_secret.secret["minio_s3_url"].value
      type  = "env"
    }
  ]

  # Common Tailscale secrets
  tailscale_secrets = [
    {
      name  = "TAILSCALE_API_KEY"
      value = data.bitwarden_secret.secret["tailscale_api_key"].value
      type  = "env"
    },
    {
      name  = "TAILSCALE_TAILNET"
      value = data.bitwarden_secret.secret["tailscale_tailnet"].value
      type  = "env"
    }
  ]

  # Common Proxmox secrets (alternative naming for environments)
  proxmox_secrets_tf = [
    {
      name  = "PM_USER"
      value = data.bitwarden_secret.secret["proxmox_api_user"].value
      type  = "env"
    },
    {
      name  = "PM_PASS"
      value = data.bitwarden_secret.secret["proxmox_api_password"].value
      type  = "env"
    },
    {
      name  = "PM_API_URL"
      value = data.bitwarden_secret.secret["proxmox_api_url"].value
      type  = "env"
    }
  ]

  # Splunk secrets
  splunk_secrets = [
    {
      name  = "SPLUNK_URL"
      value = data.bitwarden_secret.secret["splunk_url"].value
      type  = "env"
    },
    {
      name  = "SPLUNK_USERNAME"
      value = data.bitwarden_secret.secret["splunk_api_user"].value
      type  = "env"
    },
    {
      name  = "SPLUNK_PASSWORD"
      value = data.bitwarden_secret.secret["splunk_api_password"].value
      type  = "env"
    }
  ]

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
      login       = "ansible"
    }
  }

  repositories = {
    ansible_collection_homelab = {
      url = "git@github.com:timvy/ansible_collection_homelab.git"
      templates = {
        ans_os_update = {
          playbook    = "playbooks/os_update.yml"
          inventory   = "ansible_inventory_proxmox"
          environment = "ansible_proxmox"
        }
      }
    }
    ansible_inventory_homelab = {
      url = "git@github.com:timvy/ansible_inventory_homelab.git"
    }
    terraform_homelab = {
      url = "git@github.com:timvy/terraform_homelab.git"
      templates = {
        terraform_docker = {
          app         = "tofu"
          playbook    = "docker"
          inventory   = "terraform_docker"
          environment = "terraform_homelab"
          arguments = [
            "-parallelism=1"
          ]
        }
        terraform_certificates = {
          app         = "tofu"
          playbook    = "certs"
          inventory   = "terraform_certs"
          environment = "terraform_homelab_bw"
          arguments = [
            "-parallelism=1"
          ]
          schedules = {
            weekly = {
              cron_format = "0 0 * * 0"
            }
          }
        }
      }
    }
    tf-proxmox-lxc = {
      url = "git@github.com:timvy/tf-proxmox-lxc.git"
      templates = {
        terraform_LXC = {
          app         = "tofu"
          playbook    = "lxc"
          inventory   = "terraform_lxc"
          environment = "terraform_homelab_bw"
          arguments = [
            "-parallelism=1"
          ]
        }
      }
    }
    scripts = {
      url = "git@github.com:timvy/scripts-semaphore.git"
      templates = {
        sc_ts_expiry = {
          app      = "bash"
          playbook = "tailscale-expiry.sh" 
          schedules = {
            daily = {
              cron_format = "0 0 * * *"
            }
          }
        }
      }
    }
  }

  inventories = {
    ansible_inventory_proxmox = {
      name = "Proxmox"
      repository = "ansible_inventory_homelab"
      file = {
        path = "inventory/proxmox.yml"
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
    dummy = {
      name = "Dummy Inventory"
      static = {
        inventory = ""
      }
    }
  }

  # Variable groups (environments)
  environments = {
    dummy = {
      name        = "Dummy Environment"
      variables   = {}
      environment = {}
      secrets     = []
    }
    ansible_proxmox = {
      name        = "Proxmox Inventory"
      variables   = {}
      environment = {}
      secrets = [
        {
          name  = "proxmox_host"
          value = "pve-hpe.${data.bitwarden_secret.domain_tailscale.value}"
          type  = "var"
        },
        {
          name  = "PROXMOX_PASSWORD"
          value = data.bitwarden_secret.secret["proxmox_api_password"].value
          type  = "env"
        },
        {
          name  = "PROXMOX_USER"
          value = data.bitwarden_secret.secret["proxmox_api_user"].value
          type  = "env"
        },
        {
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
      secrets = concat(local.aws_secrets, [
        {
          name  = "BW_CLIENTID"
          value = data.bitwarden_secret.secret["bitwarden_client_id"].value
          type  = "env"
        },
        {
          name  = "BW_CLIENTSECRET"
          value = data.bitwarden_secret.secret["bitwarden_client_secret"].value
          type  = "env"
        },
        {
          name  = "BW_PASSWORD"
          value = data.bitwarden_secret.secret["bitwarden_password"].value
          type  = "env"
        }
      ], local.tailscale_secrets)
    }
    terraform_homelab_bw = {
      name        = "Terraform Homelab with Bitwarden Secrets"
      variables   = {}
      environment = {}
      secrets = concat(local.aws_secrets, [
        {
          name  = "BWS_ACCESS_TOKEN"
          value = data.bitwarden_secret.secret["bitwarden_auth_token"].value
          type  = "env"
        }
      ], local.proxmox_secrets_tf, local.splunk_secrets, local.tailscale_secrets)
    }
  }

  # Flatten repositories for resource
  repositories_flat = { for k, v in local.repositories : k => { url = v.url } }

  # Flatten templates with repository added
  templates = merge([for repo_key, repo in local.repositories : { for tpl_key, tpl in lookup(repo, "templates", {}) : tpl_key => merge(tpl, { repository = repo_key }) } ]...)

}
