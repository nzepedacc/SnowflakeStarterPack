# =============================================================================
# ENVIRONMENT PROD - VARIABLES
# =============================================================================

variable "snowflake_account"   { type = string }
variable "snowflake_region"   { type = string; default = "" }
variable "snowflake_user"     { type = string }
variable "snowflake_password" { type = string; sensitive = true }
variable "snowflake_role"     { type = string; default = "SYSADMIN" }
