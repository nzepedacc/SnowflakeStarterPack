# =============================================================================
# ENVIRONMENT DEV - VARIABLES
# =============================================================================
# Credenciales y parámetros del ambiente. Nunca subas terraform.tfvars al repo.
# =============================================================================

variable "snowflake_account" {
  description = "Identificador de la cuenta Snowflake (ej. xy12345 o xy12345.us-east-1). Cómo obtenerlo: Snowsight -> Admin -> Accounts -> Account identifier."
  type        = string
}

variable "snowflake_region" {
  description = "Región de la cuenta (ej. us-east-1). Opcional si va incluido en account."
  type        = string
  default     = ""
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
