# Terraform Azure Linux VM — Session Summary

> **Purpose:** Reference document for this project. Summarises architecture decisions, file structure, patterns used, and next steps discussed in the mentoring session.

---

## What Was Built

A single reusable `main.tf` that provisions a full Azure Linux VM stack for both **dev** and **prod** environments, differentiated entirely through `.tfvars` files.

### Resources Provisioned
| Resource | Naming Convention |
|---|---|
| Resource Group | `rg-<project>-<environment>` |
| Virtual Network | `vnet-<project>-<environment>` |
| Subnet | `snet-<project>-<environment>` |
| Network Security Group | `nsg-<project>-<environment>` |
| Network Interface | `nic-<project>-<environment>` |
| Public IP (optional) | `pip-<project>-<environment>` |
| Linux Virtual Machine | `vm-<project>-<environment>` |

---

## File Structure

```
.
├── main.tf          # All resource logic — never edited per environment
├── variables.tf     # Variable definitions with types, descriptions, validations
├── dev.tfvars       # Dev-specific values
├── prod.tfvars      # Prod-specific values
└── SUMMARY.md       # This file
```

> `backend.tf` and `provider.tf` were consolidated into `main.tf` in the final solution.

---

## Key Terraform Patterns Used

### Conditional Resource (optional Public IP)
```hcl
resource "azurerm_public_ip" "pip" {
  count = var.create_public_ip ? 1 : 0
  ...
}
```
Safely referenced on the NIC with:
```hcl
public_ip_address_id = length(azurerm_public_ip.pip) > 0 ? azurerm_public_ip.pip[0].id : null
```

### Locals for DRY Naming
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
```
Every resource name is derived from `local.name_prefix` — change the convention in one place, it flows everywhere.

### Backend Variable Limitation
Terraform backend blocks **cannot use input variables**. The backend is initialised before variables are resolved. Handle this by passing the state key at `init` time:
```bash
terraform init -backend-config="key=dev/terraform.tfstate"
terraform init -reconfigure -backend-config="key=prod/terraform.tfstate"
```

---

## Environment Differences (dev vs prod)

| Setting | Dev | Prod |
|---|---|---|
| VM Size | `Standard_B1s` | `Standard_D2s_v3` |
| OS Disk | `Standard_LRS` (HDD) | `Premium_LRS` (SSD) |
| Public IP | `true` | `false` |
| VNet Range | `10.0.0.0/16` | `10.1.0.0/16` |
| Subnet | `10.0.1.0/24` | `10.1.1.0/24` |
| SSH Source | Your office/home IP | Management/Bastion CIDR |

---

## Commands Reference

```bash
# Initialise for dev (run once, or after backend change)
terraform init -backend-config="key=dev/terraform.tfstate"

# Dev workflow
terraform plan  -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Switch to prod state
terraform init -reconfigure -backend-config="key=prod/terraform.tfstate"

# Prod workflow
terraform plan  -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

---

## Security Decisions

- **Password authentication disabled** — SSH key only (`disable_password_authentication = true`)
- **NSG on subnet** — explicit allow SSH from known CIDRs + deny-all-inbound catch-all at priority 4096
- **No public IP in prod** — prod VMs should be accessed via Azure Bastion, VPN Gateway, or jump box
- **Non-overlapping address spaces** — dev `10.0.x.x`, prod `10.1.x.x` — required for future VNet peering or VPN

---

## Expertise Level Assessment

This solution is **mid-level / intermediate**. It is production-viable for small workloads.

**What it does well:** naming conventions, conditional resources, remote state, NSGs, tag enforcement, variable validation, DRY locals.

**What a senior would add next:**
- Terraform **modules** (reusable VM module called per environment)
- **Azure Bastion** resource for prod SSH access
- **CI/CD pipeline** (GitHub Actions / Azure DevOps) to enforce init/plan/apply — removes manual `-backend-config` risk
- **`prevent_destroy = true`** lifecycle rule on prod resource group
- **Data sources** instead of local file paths (e.g. SSH key from Key Vault)
- **Azure Monitor / diagnostic settings** on the VM
- **Terraform workspaces** consideration

---

## Next Steps for This Project

- [ ] Replace `file("~/.ssh/id_rsa.pub")` with a Key Vault data source for prod
- [ ] Add Azure Bastion to the prod VNet
- [ ] Add `prevent_destroy = true` to prod resource group
- [ ] Wire up a CI/CD pipeline to automate `init` / `plan` / `apply`
- [ ] Extract the VM stack into a reusable Terraform module
- [ ] Add diagnostic settings / Azure Monitor alerts
