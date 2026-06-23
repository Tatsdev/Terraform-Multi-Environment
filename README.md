# Azure Linux VM with Terraform

## Project Overview

I built this project to practice writing Terraform in a way that is reusable, easy to follow, and realistic for day-to-day cloud work. The goal was to use **one main Terraform configuration** to deploy the same Azure Linux VM stack into different environments, with the differences controlled through separate `.tfvars` files instead of changing the core code.

In this version, I focused on two environments:
- **dev** – lower cost, easier to access for testing
- **prod** – more locked down and closer to what you would expect in a real deployment

This project reflects how I currently think as an **intermediate cloud engineer**: keep the design simple, use solid naming and security basics, and make choices that are practical without overengineering.

---

## What This Project Deploys

The Terraform configuration builds a full Linux VM stack in Azure, including:

- Resource Group
- Virtual Network (VNet)
- Subnet
- Network Security Group (NSG)
- Network Interface (NIC)
- Optional Public IP
- Linux Virtual Machine

I used a consistent naming pattern across all resources:

```text
<resource-type>-<project>-<environment>
```

Example names:
- `rg-myproject-dev`
- `vnet-myproject-prod`
- `vm-myproject-dev`

That keeps the deployment easy to read in the Azure portal and makes the environment obvious at a glance.

I kept the setup intentionally small. In the final version, the provider and backend configuration were folded into `main.tf` to reduce file sprawl and make the project easier to follow.

---

## My Approach

### One codebase, multiple environments

Instead of creating separate Terraform files for dev and prod, I used the same core configuration and changed only the input values through `.tfvars` files. That keeps the logic consistent between environments and reduces the chance of drift.

### Conditional resources where it makes sense

One example is the **Public IP**. Dev can create one when needed, while prod can stay private.

```hcl
resource "azurerm_public_ip" "pip" {
  count = var.create_public_ip ? 1 : 0
}
```

This was a good reminder that you can keep configurations flexible without duplicating resources.

### Cleaner naming with locals

I used `locals` to build a shared naming prefix and common tags. It is a small pattern, but it makes the code easier to maintain and avoids repeating the same strings everywhere.

### Remote state awareness

One of the practical Terraform lessons in this project was the backend limitation: **backend blocks cannot use input variables**. Because of that, the state key has to be passed during `terraform init`.

```bash
terraform init -backend-config="key=dev/terraform.tfstate"
terraform init -reconfigure -backend-config="key=prod/terraform.tfstate"
```

It is a small detail, but it matters when you start separating environments properly.

---

## Dev vs Prod Design Choices

I wanted dev and prod to feel intentionally different rather than being copies of each other.

### Dev
- Smaller VM size to keep cost down
- Standard HDD disk
- Public IP enabled for easier testing
- SSH access limited to a known IP
- Network range: `10.0.0.0/16`

### Prod
- Larger VM size for more realistic workload capacity
- Premium SSD disk
- No public IP
- SSH expected through a safer route such as Bastion, VPN, or a jump box
- Network range: `10.1.0.0/16`

This separation helped me think more clearly about environment design instead of treating production like an afterthought.

---

## Security Decisions

I tried to keep the security choices practical and realistic for a project at this level:

- **Password authentication is disabled**
- **SSH key access only**
- **NSG rules allow SSH only from approved CIDRs**
- **Production does not expose a public IP**
- **Address spaces do not overlap between environments**

These are not advanced controls, but they are the kind of fundamentals I think every cloud engineer should get comfortable with early.

---

## Commands I Used

### Dev

```bash
terraform init -backend-config="key=dev/terraform.tfstate"
terraform plan -var-file="dev.tfvars" -out= tfdev
terraform apply "tfdev"
```
### Prod

```bash
terraform init -reconfigure -backend-config="key=prod/terraform.tfstate"
terraform plan -var-file="prod.tfvars" -out= tfprod
terraform apply "tfprod"
```
---

## What I Would Improve Next

If I continued this project, these would be my next steps:

- Refactor the VM stack into a reusable **Terraform module**
- Add **Azure Bastion** for safer production access
- Pull the SSH public key from **Azure Key Vault** instead of a local file
- Add `prevent_destroy = true` for production protection
- Introduce a **CI/CD pipeline** with GitHub Actions or Azure DevOps
- Add **Azure Monitor** or diagnostic settings for visibility

That would move the project from a strong learning build into something closer to production-ready infrastructure.
