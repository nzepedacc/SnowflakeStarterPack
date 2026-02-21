# =============================================================================
# MÓDULO RBAC - OUTPUTS
# =============================================================================

output "object_role_names_read" {
  description = "Nombres de los object roles de lectura creados."
  value       = { for k, r in snowflake_role.object_read : k => r.name }
}

output "object_role_names_write" {
  description = "Nombres de los object roles de escritura creados."
  value       = { for k, r in snowflake_role.object_write : k => r.name }
}

output "object_role_names_admin" {
  description = "Nombres de los object roles de administración creados."
  value       = { for k, r in snowflake_role.object_admin : k => r.name }
}

output "functional_role_names" {
  description = "Nombres de los functional roles creados."
  value       = { for k, r in snowflake_role.functional : k => r.name }
}

output "user_names" {
  description = "Nombres de usuarios creados (login names)."
  value       = [for u in snowflake_user.users : u.name]
}
