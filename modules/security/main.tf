# =============================================================================
# MÓDULO: SECURITY
# =============================================================================
# Gestiona políticas de contraseña y documenta MFA. La password policy se
# crea en un schema dedicado; el attachment a nivel cuenta la aplica a todos
# los usuarios que usen esa policy (o por defecto si se asigna a la cuenta).
#
# APRENDE MÁS (Password Policy): https://docs.snowflake.com/en/user-guide/security-password-policy
# APRENDE MÁS (MFA): https://docs.snowflake.com/en/user-guide/security-mfa
# =============================================================================

locals {
  security_db_name   = "ONBOARDING_SECURITY_${var.ambiente}"
  security_schema    = "POLICIES"
}

# -----------------------------------------------------------------------------
# Database y Schema para políticas
# -----------------------------------------------------------------------------
# Qué hace: Crea una base de datos y schema para albergar la password policy.
# Por qué: Las password policies en Snowflake son objetos de schema.
# Sin esto: No tendríamos dónde crear la política de forma organizada.
# -----------------------------------------------------------------------------
resource "snowflake_database" "security" {
  name    = local.security_db_name
  comment = "Base de datos para políticas de seguridad - Onboarding"
}

resource "snowflake_schema" "policies" {
  database = snowflake_database.security.name
  name     = local.security_schema
  comment  = "Schema para password y authentication policies"
}

# -----------------------------------------------------------------------------
# PASSWORD POLICY (ONBOARDING_PASSWORD_POLICY)
# -----------------------------------------------------------------------------
# Qué hace: Define requisitos de complejidad y bloqueo para contraseñas.
# Por qué: Reduce riesgo de contraseñas débiles y fuerza rotación/historial.
# Sin esto: Los usuarios podrían usar contraseñas triviales.
# -----------------------------------------------------------------------------
resource "snowflake_password_policy" "onboarding" {
  database = snowflake_database.security.name
  schema   = snowflake_schema.policies.name
  name     = var.password_policy_name

  min_length          = var.min_length
  min_upper_case_chars = var.min_upper_case_chars
  min_lower_case_chars = var.min_lower_case_chars
  min_numeric_chars    = var.min_numeric_chars
  min_special_chars    = var.min_special_chars
  max_retries          = var.max_retries
  lockout_time_mins    = var.lockout_time_mins
  password_history     = var.password_history

  comment = "Política de contraseña para onboarding: min 12 caracteres, may/min/num/special, 5 intentos, historial 5"
}

# -----------------------------------------------------------------------------
# ATTACHMENT A NIVEL CUENTA (opcional)
# -----------------------------------------------------------------------------
# Qué hace: Aplica la password policy por defecto a la cuenta.
# Por qué: Así todos los usuarios heredan la política salvo que se asigne otra.
# Sin esto: La policy existiría pero no se aplicaría a nadie hasta asignarla.
# -----------------------------------------------------------------------------
resource "snowflake_account_password_policy_attachment" "default" {
  password_policy_identifier = "${snowflake_database.security.name}.${snowflake_schema.policies.name}.${snowflake_password_policy.onboarding.name}"
}

# -----------------------------------------------------------------------------
# NOTA SOBRE MFA (Authentication Policy)
# -----------------------------------------------------------------------------
# En Snowflake, MFA se controla con "Authentication Policies" (CREATE AUTHENTICATION POLICY).
# El provider Terraform Snowflake-Labs 0.87 puede no incluir aún el recurso
# snowflake_authentication_policy. Para activar MFA obligatorio:
#
# 1. En la UI: Account -> Security -> Authentication Policy -> Create.
# 2. Configurar MFA_ENROLLMENT = 'REQUIRED'.
# 3. O vía SQL (ejecutar como ACCOUNTADMIN):
#    CREATE AUTHENTICATION POLICY ONBOARDING_MFA_POLICY
#      MFA_ENROLLMENT = 'REQUIRED';
#    ALTER ACCOUNT SET AUTHENTICATION_POLICY = ONBOARDING_MFA_POLICY;
#
# Cómo el usuario activa MFA: Snowsight -> Profile -> Security -> Multi-Factor Auth -> Enroll.
# APRENDE MÁS: https://docs.snowflake.com/en/user-guide/security-mfa
# =============================================================================
