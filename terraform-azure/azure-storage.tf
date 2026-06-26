# 7. Create a Storage Account (Cloud Object Storage)
resource "azurerm_storage_account" "storage" {
  name                     = "subhashdevopsstorage" # Must be globally unique and lowercase only!
  resource_group_name      = azurerm_resource_group.student_rg.name
  location                 = azurerm_resource_group.student_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally Redundant Storage (Cheapest & fits free limits)

  tags = {
    Environment = "Learning"
  }
}