# Example: basic

Minimum invocation of the `azure-account-network-vnet-peering` module, peering a Databricks spoke VNet to a hub VNet in the same Azure subscription.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your subscription ID, VNet names, resource IDs, and resource group names.
2. Configure Azure credentials (via `az login`, environment variables, or service principal).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `azurerm` provider at the root with a subscription ID.
- Passing VNet names and IDs to the module for both the local (spoke) and remote (hub) VNets.
- Enabling `allow_forwarded_traffic = true` for hub-and-spoke topologies where traffic is forwarded through a firewall or NVA in the hub.

## Outputs

- `local_peering_id` — Azure resource ID of the spoke-to-hub peering object.
- `remote_peering_id` — Azure resource ID of the hub-to-spoke peering object.
