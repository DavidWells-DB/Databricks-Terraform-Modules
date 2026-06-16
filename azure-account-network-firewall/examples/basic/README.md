# Example: basic

Minimum invocation of the `azure-account-network-firewall` module in a hub-spoke topology for Azure Databricks.

## What this example demonstrates

- Configuring the `azurerm` provider at the root.
- Passing Databricks-specific Azure Service Tag network rules for `eastus`.
- Forcing spoke subnet egress through the firewall via a route table association.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the required values.
2. Ensure you have an existing hub VNet with an `AzureFirewallSubnet` (minimum /26) and spoke subnets to route through the firewall. The `azure-account-network-vnet` module can create these.
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## Prerequisites

- A pre-existing Azure resource group.
- A pre-existing hub VNet with a subnet named `AzureFirewallSubnet` (minimum /26).
- Pre-existing spoke subnets whose egress should be forced through the firewall.

## Outputs

- `firewall_id` — Resource ID of the Azure Firewall.
- `firewall_private_ip` — Private IP of the firewall; useful for verifying route next-hop.
- `firewall_public_ip` — Public IP of the firewall; allowlist in any external services.
- `firewall_policy_id` — Resource ID of the firewall policy; pass to additional rule collection group resources.
- `route_table_id` — Resource ID of the forced-tunnel route table associated with spoke subnets.
