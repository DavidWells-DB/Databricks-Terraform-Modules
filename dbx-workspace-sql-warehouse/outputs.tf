output "warehouse_id" {
  description = "The ID of the SQL warehouse. Use this to reference the warehouse in queries, dashboards, and alerts."
  value       = databricks_sql_endpoint.this.id
}

output "warehouse_name" {
  description = "The name of the SQL warehouse."
  value       = databricks_sql_endpoint.this.name
}

output "jdbc_url" {
  description = "JDBC connection URL for the SQL warehouse. Use this to connect external tools via JDBC."
  value       = databricks_sql_endpoint.this.jdbc_url
}

output "odbc_params" {
  description = "ODBC connection parameters as a structured object. Contains host, path, protocol, and port for ODBC connections."
  value       = databricks_sql_endpoint.this.odbc_params
}

output "data_source_id" {
  description = "The data source ID for the warehouse. Use this ID when creating SQL queries, dashboards, or alerts via the Databricks SQL API."
  value       = databricks_sql_endpoint.this.data_source_id
}
