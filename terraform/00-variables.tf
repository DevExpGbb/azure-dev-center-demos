variable "subscription_id" {
  description = "value of the subscription_id"
  type = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group in which the resources should be deployed"
  type = string
}

variable "location" {
  description = "Azure Region in which the resources should be deployed"
  type = string
}

variable "custom_images" {
  description = "Name of the custom image to create"
  type = map(object({
    publisher_name = string
    offer_name = string
    sku = string
    semver = string
  }))
  default = {
    jetbrains = {
      publisher_name = "devgbb"
      offer_name = "jetbrainsbox"
      sku = "demo"
      semver = "1.0.0"
    }
    eclipse = {
      publisher_name = "devgbb"
      offer_name = "eclipsebox"
      sku = "demo"
      semver = "1.0.0"
    }
    vscode = {
      publisher_name = "devgbb"
      offer_name = "vscodebox"
      sku = "demo"
      semver = "1.0.0"
    }
  }
}

variable "gh_pat_token" {
  description = "value of the GH Pat Token used for acessing a Catalog hosted in a GH Repo"
  type = string
}