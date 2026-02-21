# =============================================================================
# ENVIRONMENT DEV - VARIABLES
# =============================================================================
# Credenciales y parámetros del ambiente. Nunca subas terraform.tfvars al repo.
# =============================================================================

variable "snowflake_account" {
  description = "Identificador legacy (ej. xy12345). Si usas organization_name + account_name, puede quedar vacío."
  type        = string
  default     = ""
}

variable "snowflake_organization_name" {
  description = "Nombre de la organización (ej. LCMSCLG si tu identificador es LCMSCLG.WAC97526). Preferir esto + account_name en cuentas recientes."
  type        = string
  default     = ""
}

variable "snowflake_account_name" {
  description = "Nombre de la cuenta dentro de la org (ej. WAC97526). Usar junto con snowflake_organization_name."
  type        = string
  default     = ""
}

variable "snowflake_region" {
  description = "Región de la cuenta (ej. us-east-1). Recomendado cuando usas organization_name + account_name."
  type        = string
  default     = ""
}

variable "snowflake_host" {
  description = "Opcional: host completo (ej. WAC97526.us-west-2.aws.snowflakecomputing.com). Usar si el certificado TLS falla con account+region; obtén la URL desde la UI de Snowflake al conectarte."
  type        = string
  default     = ""
}

variable "snowflake_insecure_mode" {
  description = "Si true, no verifica el certificado TLS (solo para pruebas locales si falla el cert). No usar en producción."
  type        = bool
  default     = false
}

variable "snowflake_user" {
  description = "Usuario con privilegios para crear objetos (recomendado: ACCOUNTADMIN o SYSADMIN)."
  type        = string
}

variable "snowflake_password" {
  description = "Contraseña del usuario. Preferible usar variable de entorno TF_VAR_snowflake_password."
  type        = string
  sensitive   = true
}

variable "snowflake_role" {
  description = "Role con el que ejecutar Terraform (ej. SYSADMIN o ACCOUNTADMIN)."
  type        = string
  default     = "SYSADMIN"
}
