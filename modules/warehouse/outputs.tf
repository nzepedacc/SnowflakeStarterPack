# =============================================================================
# MÓDULO WAREHOUSE - OUTPUTS
# =============================================================================

output "warehouse_names" {
  description = "Nombres de los warehouses creados."
  value       = { for k, w in snowflake_warehouse.this : k => w.name }
}

output "warehouse_ids" {
  description = "Mapa propósito -> nombre del warehouse (para asignar default_warehouse a usuarios)."
  value       = { for k, w in snowflake_warehouse.this : k => w.name }
}
