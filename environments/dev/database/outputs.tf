output "db_endpoint" {
  description = "Array containing the full resource object and attributes for all DB proxy endpoints created"
  value       = module.database.db_endpoint
}