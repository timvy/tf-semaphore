resource "semaphoreui_project" "base" {
  name               = "base"
  alert              = true
  max_parallel_tasks = 0
}

data "bitwarden_secret" "ssh_semaphore_github" {
  key = "ssh_semaphore_github"
}

resource "semaphoreui_project_key" "github" {
  project_id = semaphoreui_project.base.id
  name       = "github"
  ssh = {
    private_key = data.bitwarden_secret.ssh_semaphore_github.value
  }
}

resource "semaphoreui_project_repository" "tf-semaphore" {
  project_id = semaphoreui_project.base.id
  name       = "tf-semaphore"
  url        = "git@github.com:timvy/tf-semaphore.git"
  branch     = "main"
  ssh_key_id = semaphoreui_project_key.github.id
}

resource "semaphoreui_project_inventory" "homelab" {
  project_id          = semaphoreui_project.base.id
  name                = "homelab"
  terraform_workspace = {
    workspace = "homelab"
  }
  ssh_key_id          = semaphoreui_project_key.github.id
}

data "bitwarden_secret" "bitwarden_secrets_semaphore_token" {
  key = "bitwarden_secrets_semaphore_token"
}
data "bitwarden_secret" "minio_tf_access_key" {
  key = "minio_tf_access_key"
}
data "bitwarden_secret" "minio_tf_secret" {
  key = "minio_tf_secret"
}
data "bitwarden_secret" "minio_s3_url" {
  key = "minio_s3_url"
}
data "bitwarden_secret" "semaphore_api_admin" {
  key = "semaphore_api_admin"
}

resource "semaphoreui_project_environment" "homelab" {
  project_id  = semaphoreui_project.base.id
  name        = "homelab"
  secrets = [{
    name  = "BWS_ACCESS_TOKEN"
    type  = "env"
    value = data.bitwarden_secret.bitwarden_secrets_semaphore_token.value
  },{
    name  = "AWS_ACCESS_KEY_ID"
    type  = "env"
    value = data.bitwarden_secret.minio_tf_access_key.value
  },{
    name  = "AWS_SECRET_ACCESS_KEY"
    type  = "env"
    value = data.bitwarden_secret.minio_tf_secret.value
  },{
    name  = "AWS_ENDPOINT_URL_S3"
    type  = "env"
    value = data.bitwarden_secret.minio_s3_url.value
  },{
    name = "SEMAPHOREUI_HOSTNAME"
    type = "env"
    value = "localhost"
  },{
    name = "SEMAPHOREUI_API_TOKEN"
    type = "env"
    value = data.bitwarden_secret.semaphore_api_admin.value
  },{
    name = "SEMAPHOREUI_PROTOCOL"
    type = "env"
    value = "http"
} 
  ]
}

resource "semaphoreui_project_template" "homelab" {
  allow_override_args_in_task = true
  name                        = "homelab"
  project_id                  = semaphoreui_project.base.id
  app                         = "tofu"
  environment_id              = semaphoreui_project_environment.homelab.id
  inventory_id                = semaphoreui_project_inventory.homelab.id
  playbook                    = "homelab"
  repository_id               = semaphoreui_project_repository.tf-semaphore.id
}
