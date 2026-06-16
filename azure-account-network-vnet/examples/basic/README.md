# Example: basic

Minimum invocation of the `azure-account-network-vnet` module for a Databricks VNet injection setup on Azure.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Azure subscription ID and resource group name.
2. Ensure the resource group already exists (or create it separately before running this example).
3. Configure Azure credentials (via `az login`, environment variables, or a service principal).
4. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `azurerm` provider at the root composition.
- Creating a VNet with host and container subnets suitable for Databricks VNet injection.
- Using named subnet and NSG inputs (no PE subnet in this minimal example).
- How to wire the module outputs to a downstream workspace creation module.

## Outputs

- `vnet_id` — Pass to `azurerm_databricks_workspace` `custom_parameters.virtual_network_id`.
- `host_subnet_id` — Pass to `custom_parameters` for the host subnet.
- `container_subnet_id` — Pass to `custom_parameters` for the container subnet.
- `nsg_id` — Reference for any additional NSG rule management outside this module.
