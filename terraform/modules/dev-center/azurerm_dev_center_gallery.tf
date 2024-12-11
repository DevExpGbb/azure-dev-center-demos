resource "azurerm_dev_center_gallery" "default" {
  name              = "dev-center-gallery"
  dev_center_id     = azurerm_dev_center.default.id
  shared_gallery_id = var.shared_gallery_id
}