# =============================================================================
# VERSIONES DE TERRAFORM Y PROVIDERS (raíz del proyecto)
# =============================================================================
# Este archivo centraliza las restricciones de versión. Los environments
# pueden incluir este archivo o declarar su propio required_providers.
# Se usa ~> 0.87 para permitir parches (0.87.x) sin saltar a 0.88.
#
# APRENDE MÁS (Terraform): https://developer.hashicorp.com/terraform/language/expressions/version-constraints
# APRENDE MÁS (Provider Snowflake): https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
}
