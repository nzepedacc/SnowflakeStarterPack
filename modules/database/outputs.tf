# =============================================================================
# MÓDULO DATABASE - OUTPUTS
# =============================================================================
# Valores que este módulo expone para que otros módulos o el root puedan
# usarlos (por ejemplo, nombres de database/schema para asignar privilegios).
# =============================================================================

output "database_name" {
  description = "Nombre de la base de datos creada (<DOMINIO>_<AMBIENTE>)."
  value       = snowflake_database.this.name
}

output "schema_name" {
  description = "Nombre del schema creado dentro de la base de datos."
  value       = snowflake_schema.this.name
}

output "table_names" {
  description = "Lista de nombres de tablas creadas en el schema."
  value       = [for t in snowflake_table.tables : t.name]
}

output "qualified_schema" {
  description = "Nombre cualificado del schema (DATABASE.SCHEMA) para uso en grants y queries."
  value       = "${snowflake_database.this.name}.${snowflake_schema.this.name}"
}
