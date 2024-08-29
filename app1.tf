variable "location" {
  default = "westus"
}

variable "tagList" {
  default = {
    env = "dev"
    project = "app1"
    owner = "ag"
  }
}

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0.1"
    }
  }
  required_version = ">= 1.9.5"
  backend "azurerm" {
    resource_group_name  = "rg-tp-tfstate"
    storage_account_name = "sttpstatestore"
    container_name       = "tfstate"
    key                  = "live.terraform.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  subscription_id = "b23e8ebe-87de-4ea1-8da8-634ea9c3bdf8"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-tp-app1"
  location = var.location
}

resource "azurerm_service_plan" "plan" {
  name                         = "asptpapp1"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = var.tagList
  app_service_environment_id   = null
  os_type                      = "Linux"
  per_site_scaling_enabled     = false
  sku_name                     = "F1"
  worker_count           = 1
  zone_balancing_enabled = false
}

resource "azurerm_linux_web_app" "app" {
  lifecycle {
    replace_triggered_by = [
      azurerm_service_plan.plan
    ]
  }
  name                                     = "apptpapp1"
  location                                 = var.location
  resource_group_name                      = azurerm_resource_group.rg.name
  tags                                     = var.tagList
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING      = azurerm_application_insights.appi.instrumentation_key
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    XDT_MicrosoftApplicationInsights_Mode      = "Recommended"
  }
  client_affinity_enabled                  = false
  client_certificate_enabled               = false
  client_certificate_exclusion_paths       = null
  client_certificate_mode                  = "Required"
  enabled                                  = true
  ftp_publish_basic_authentication_enabled = false
  https_only                               = true
  public_network_access_enabled            = true
  service_plan_id                          = azurerm_service_plan.plan.id
  virtual_network_subnet_id                      = null
  webdeploy_publish_basic_authentication_enabled = false
  zip_deploy_file                                = null
  site_config {
    always_on                                     = false
    api_definition_url                            = null
    api_management_api_id                         = null
    app_command_line                              = null
    container_registry_managed_identity_client_id = null
    container_registry_use_managed_identity       = false
    default_documents                             = ["Default.htm", "Default.html", "Default.asp", "index.htm", "index.html", "iisstart.htm", "default.aspx", "index.php", "hostingstart.html"]
    ftps_state                                    = "FtpsOnly"
    # health_check_eviction_time_in_min             = 0
    health_check_path                             = null
    http2_enabled                                 = false
    ip_restriction_default_action                 = null
    load_balancing_mode                           = "LeastRequests"
    local_mysql_enabled                           = false
    managed_pipeline_mode                         = "Integrated"
    minimum_tls_version                           = jsonencode(1.2)
    remote_debugging_enabled                      = false
    remote_debugging_version                      = null
    scm_ip_restriction_default_action             = null
    scm_minimum_tls_version                       = jsonencode(1.2)
    scm_use_main_ip_restriction                   = false
    use_32_bit_worker                             = true
    vnet_route_all_enabled                        = false
    websockets_enabled                            = false
    worker_count                                  = 1
    application_stack {
      dotnet_version           = "8.0"
    }
  }
}

resource "azurerm_application_insights" "appi" {
  name                                  = "appitpapp1"
  location                              = var.location
  resource_group_name                   = azurerm_resource_group.rg.name
  tags                                  = var.tagList
  application_type                      = "web"
  daily_data_cap_in_gb                  = 1
  daily_data_cap_notifications_disabled = false
  disable_ip_masking                    = false
  force_customer_storage_for_profiler   = false
  internet_ingestion_enabled            = true
  internet_query_enabled                = true
  local_authentication_disabled         = false
  retention_in_days                     = 90
  sampling_percentage                   = 0
  # workspace_id = azurerm_log_analytics_workspace.workspace.id
}

# resource "azurerm_log_analytics_workspace" "workspace" {
#   name                                    = "logtpapp1"
#   location                                = var.location
#   resource_group_name                     = azurerm_resource_group.rg.name
#   tags                                    = var.tagList
#   allow_resource_only_permissions         = true
#   cmk_for_query_forced                    = false
#   daily_quota_gb                          = -1
#   data_collection_rule_id                 = null
#   immediate_data_purge_on_30_days_enabled = false
#   internet_ingestion_enabled              = true
#   internet_query_enabled                  = true
#   local_authentication_disabled           = false
#   reservation_capacity_in_gb_per_day      = null
#   retention_in_days                       = 30
#   sku                                     = "PerGB2018"
# }

resource "azurerm_monitor_action_group" "smartdetection" {
  name                = "agtpapp1smartdetect"
  location            = "global"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tagList
  enabled             = true
  short_name          = "SmartDetect"
  arm_role_receiver {
    name                    = "Monitoring Contributor"
    role_id                 = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
    use_common_alert_schema = true
  }
  arm_role_receiver {
    name                    = "Monitoring Reader"
    role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    use_common_alert_schema = true
  }
}
