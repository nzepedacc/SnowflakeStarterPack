# =============================================================================
# MÓDULO SECURITY - OUTPUTS
# =============================================================================

output "password_policy_qualified_name" {
  description = "Nombre cualificado de la password policy (DATABASE.SCHEMA.POLICY)."
  value       = "${snowflake_database.security.name}.${snowflake_schema.policies.name}.${snowflake_password_policy.onboarding.name}"
}

output "security_database_name" {
  description = "Nombre de la base de datos donde viven las políticas."
  value       = snowflake_database.security.name
}
