resource "azurerm_key_vault" "default" {
  name                = "${azurerm_resource_group.default.name}-kv"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  enable_rbac_authorization = true
  enabled_for_deployment = false
  enabled_for_disk_encryption = false
  enabled_for_template_deployment = false
  soft_delete_retention_days = 7
  purge_protection_enabled = false
}

resource "time_sleep" "wait_for_kv_role_permissions" {
  depends_on = [ azurerm_role_assignment.current-user-kv-officer ]
  create_duration = "60s"  
}

resource "azurerm_key_vault_secret" "gh-pat" {
  depends_on = [ time_sleep.wait_for_kv_role_permissions ]

  name         = "gh-pat"
  value        = var.gh_pat_token
  key_vault_id = azurerm_key_vault.default.id
}