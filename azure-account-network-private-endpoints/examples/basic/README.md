# Example: basic

Minimum invocation of the `azure-account-network-private-endpoints` module. Creates the back-end private endpoint, the `privatelink.azuredatabricks.net` DNS zone, and the spoke VNet link.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Azure subscription ID, resource group, and workspace resource ID.
2. Ensure your Azure credentials are configured (via `az login`, environment variables, or managed identity).
3. Ensure the target subnet has private endpoint network policies disabled:

   ```bash
   az network vnet subnet update \
     --resource-group <rg> \
     --vnet-name <vnet> \
     --name <subnet> \
     --disable-private-endpoint-network-policies true
   ```

4. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `azurerm` provider at the root with a subscription ID.
- Minimum back-end-only private endpoint configuration (no front-end or browser auth).
- How to pass all required inputs to the module.

## Outputs

- `back_end_pe_id` — Azure resource ID of the back-end private endpoint.
- `private_dns_zone_id` — Azure resource ID of the `privatelink.azuredatabricks.net` DNS zone.
