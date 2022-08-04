output "api_gateway_endpoint" {
  description = "api gateway endpoint"
  value       = data.local_file.api_gateway_endpoint.content
}