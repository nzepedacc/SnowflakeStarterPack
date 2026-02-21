# =============================================================================
# ENVIRONMENT UAT - VARIABLES
# =============================================================================
# Mismas variables que DEV para conexión (misma cuenta Snowflake, otros recursos con sufijo _UAT).
# =============================================================================

variable "snowflake_account" {
  type    = string
  default = ""
}

variable "snowflake_organization_name" {
  type    = string
  default = ""
}

variable "snowflake_account_name" {
  type    = string
  default = ""
}

variable "snowflake_region" {
  type    = string
  default = ""
}

variable "snowflake_host" {
  type    = string
  default = ""
}

variable "snowflake_insecure_mode" {
  type    = bool
  default = false
}

variable "snowflake_user" {
  type = string
}

variable "snowflake_password" {
  type      = string
  sensitive = true
}

variable "snowflake_role" {
  type    = string
  default = "SYSADMIN"
}
