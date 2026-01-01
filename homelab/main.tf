resource "semaphoreui_project" "homelab" {
  name               = "homelab"
  alert              = true
  max_parallel_tasks = 0
}

data "bitwarden_secret" "secret" {
  for_each = toset(local.bitwarden_secrets)

  key = each.key
}

resource "semaphoreui_project_key" "ssh" {
  for_each = local.project_keys_ssh

  project_id = semaphoreui_project.homelab.id
  name       = each.key
  ssh = {
    private_key = each.value.private_key
    user        = lookup(each.value, "user", "")
    # login        = lookup(each.value, "login", "")
  }
}

resource "semaphoreui_project_repository" "repositories" {
  for_each = local.repositories

  project_id = semaphoreui_project.homelab.id
  name       = each.key
  url        = each.value.url
  branch     = "main"
  ssh_key_id = semaphoreui_project_key.ssh["semaphore_github"].id
}

resource "semaphoreui_project_inventory" "inventory" {
  for_each = local.inventories

  project_id          = semaphoreui_project.homelab.id
  name                = each.value.name
  file                = lookup(each.value, "file", null)
  static              = lookup(each.value, "static", null)
  static_yaml         = lookup(each.value, "static_yaml", null)
  terraform_workspace = lookup(each.value, "terraform_workspace", null)
  ssh_key_id          = semaphoreui_project_key.ssh["semaphore_homelab"].id
}

resource "semaphoreui_project_environment" "environment" {
  for_each    = local.environments
  project_id  = semaphoreui_project.homelab.id
  name        = each.value.name
  variables   = { for k, v in each.value.variables : k => v }
  environment = { for k, v in each.value.environment : k => v }
  secrets = [for s in each.value.secrets : {
    name  = s.name
    value = s.value
    type  = s.type
  }]
}

resource "semaphoreui_project_template" "template" {
  for_each = local.templates

  allow_override_args_in_task = true
  app                         = lookup(each.value, "app", null)
  description                 = lookup(each.value, "description", null)
  environment_id              = semaphoreui_project_environment.environment[each.value.environment].id
  inventory_id                = semaphoreui_project_inventory.inventory[each.value.inventory].id
  name                        = each.key
  playbook                    = each.value.playbook
  project_id                  = semaphoreui_project.homelab.id
  repository_id               = semaphoreui_project_repository.repositories[each.value.repository].id
  arguments                   = lookup(each.value, "arguments", null)
}

locals {
  template_schedules = merge([
    for template, template_value in local.templates : {
      for key, value in lookup(template_value, "schedules", {}) :
      "${template}-${key}" => merge(value, {
        template = template
        name     = key
      })
    }
  ]...)
}

resource "semaphoreui_project_schedule" "schedules" {
  for_each = local.template_schedules

  name        = each.value.name
  enabled     = lookup(each.value, "enabled", true)
  project_id  = semaphoreui_project.homelab.id
  cron_format = lookup(each.value, "cron_format", "")
  template_id = semaphoreui_project_template.template[each.value.template].id
}
