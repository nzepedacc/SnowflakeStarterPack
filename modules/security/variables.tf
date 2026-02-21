# =============================================================================
# MÓDULO SECURITY - VARIABLES
# =============================================================================
# Políticas de contraseña y autenticación (MFA) para el onboarding.
# =============================================================================

variable "ambiente" {
  description = "Ambiente (DEV, UAT, PROD). Usado en nombres de recursos."
  type        = string
}

variable "password_policy_name" {
  description = "Nombre de la política de contraseña (ej. ONBOARDING_PASSWORD_POLICY)."
  type        = string
  default     = "ONBOARDING_PASSWORD_POLICY"
}

variable "min_length" {
  description = "Longitud mínima de la contraseña en caracteres."
  type        = number
  default     = 12
}

variable "min_upper_case_chars" {
  description = "Número mínimo de mayúsculas requeridas."
  type        = number
  default     = 1
}

variable "min_lower_case_chars" {
  description = "Número mínimo de minúsculas requeridas."
  type        = number
  default     = 1
}

variable "min_numeric_chars" {
  description = "Número mínimo de dígitos requeridos."
  type        = number
  default     = 1
}

variable "min_special_chars" {
  description = "Número mínimo de caracteres especiales requeridos."
  type        = number
  default     = 1
}

variable "max_retries" {
  description = "Intentos fallidos antes de bloquear la cuenta (lockout)."
  type        = number
  default     = 5
}

variable "password_history" {
  description = "Cantidad de contraseñas anteriores que no se pueden reutilizar."
  type        = number
  default     = 5
}

variable "lockout_time_mins" {
  description = "Minutos de bloqueo tras superar max_retries."
  type        = number
  default     = 15
}
