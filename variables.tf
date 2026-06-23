# =============================================================================
# variables.tf
# =============================================================================
# This file is the contract between your main.tf and your operators.
# Every value that might differ between environments, regions, or use cases
# should be a variable. This keeps main.tf logic-only and makes it reusable.
#
# Best practice: always include type, description, and a sensible default
# where one exists. Leave no default for anything sensitive or environment-
# specific — that forces the operator to supply it explicitly.
# =============================================================================

# -----------------------------------------------------------------------------
# Project / Environment identity
# -----------------------------------------------------------------------------

variable "project_name" {
  type        = string
  description = "Short project name used in resource naming. e.g. 'myapp'"
}

variable "environment" {
  type        = string
  description = "Deployment environment. e.g. 'dev' or 'prod'"

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "environment must be one of: dev, prod, staging."
  }
}

# -----------------------------------------------------------------------------
# Location
# -----------------------------------------------------------------------------

variable "location" {
  type        = string
  description = "Azure region for all resources. e.g. 'southafricanorth'"
  default     = "southafricanorth"
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network. Use non-overlapping ranges per environment."
  # Dev example:  ["10.0.0.0/16"]
  # Prod example: ["10.1.0.0/16"]
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefix(es) for the subnet. Must fall within vnet_address_space."
  # Dev example:  ["10.0.1.0/24"]
  # Prod example: ["10.1.1.0/24"]
}

variable "create_public_ip" {
  type        = bool
  description = "Set to true to create and attach a Public IP to the VM. Use true for dev, false for prod."
  default     = false
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks allowed to reach the VM on port 22. Restrict to known IPs."
  # Example: ["203.0.113.10/32"]  -- your office/home IP
}

# -----------------------------------------------------------------------------
# Virtual Machine
# -----------------------------------------------------------------------------

variable "vm_size" {
  type        = string
  description = "Azure VM SKU size. e.g. 'Standard_B1s' for dev, 'Standard_D2s_v3' for prod."
}

variable "admin_username" {
  type        = string
  description = "Admin username for the Linux VM."
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key file. e.g. '~/.ssh/id_rsa.pub'"
  default     = "~/.ssh/id_rsa.pub"
}

variable "os_disk_type" {
  type        = string
  description = "Storage account type for the OS disk. 'Standard_LRS' for dev, 'Premium_LRS' for prod."
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_type)
    error_message = "os_disk_type must be Standard_LRS, StandardSSD_LRS, or Premium_LRS."
  }
}

# -----------------------------------------------------------------------------
# VM Image
# -----------------------------------------------------------------------------
# These are variablised so you can update the image without changing main.tf.
# Keeping them in tfvars also gives you a clear audit trail of what image
# each environment is running.

variable "image_publisher" {
  type        = string
  description = "Publisher of the VM image."
  default     = "Canonical"
}

variable "image_offer" {
  type        = string
  description = "Offer name of the VM image."
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  type        = string
  description = "SKU of the VM image."
  default     = "22_04-lts"
}

variable "image_version" {
  type        = string
  description = "Version of the VM image. Use 'latest' for most cases."
  default     = "latest"
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
# Tagging is essential in Azure for cost management, compliance, and
# identifying resource ownership. These tags get merged with mandatory tags
# (Environment, ManagedBy) in the locals block in main.tf.

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources. Environment and ManagedBy are added automatically."
  default     = {}
}
