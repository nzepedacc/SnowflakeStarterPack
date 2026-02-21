# =============================================================================
# MÓDULO DATABASE - VARIABLES
# =============================================================================
# Todas las entradas configurables del módulo. Permiten reutilizar el módulo
# para distintos dominios y ambientes sin duplicar código.
# =============================================================================

# -----------------------------------------------------------------------------
# Identificación del dominio y ambiente
# -----------------------------------------------------------------------------

variable "dominio" {
  description = "Nombre del dominio de negocio (ERP, CRM, SCM). Se usa en el nombre de la base de datos: <DOMINIO>_<AMBIENTE>."
  type        = string

  validation {
    condition     = contains(["ERP", "CRM", "SCM"], var.dominio)
    error_message = "dominio debe ser uno de: ERP, CRM, SCM."
  }
}

variable "ambiente" {
  description = "Ambiente de despliegue (DEV, UAT, PROD). Determina el sufijo del nombre de la base de datos."
  type        = string

  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.ambiente)
    error_message = "ambiente debe ser uno de: DEV, UAT, PROD."
  }
}

variable "schema_name" {
  description = "Nombre del schema dentro de la base de datos. Por convención no usamos PUBLIC; usamos nombres de negocio (FINANCE, CUSTOMERS, LOGISTICS)."
  type        = string
}

variable "comment" {
  description = "Comentario descriptivo de la base de datos para documentación en Snowflake."
  type        = string
  default     = "Base de datos creada por Terraform - Snowflake Onboarding"
}

variable "data_retention_time_in_days" {
  description = "Días de retención del Time Travel en la base de datos. En cuentas trial suele estar limitado por la cuenta."
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Definición de tablas del dominio
# -----------------------------------------------------------------------------
# Estructura: mapa de nombre_tabla -> { columns = [ { name, type } ] }
# Ejemplo: { "INVOICES" = { columns = [ { name = "id", type = "NUMBER" }, ... ] } }
# -----------------------------------------------------------------------------
variable "tables_config" {
  description = "Mapa de tablas a crear en el schema. Cada entrada es el nombre de la tabla (PLURAL) y una lista de columnas con name y type."
  type = map(object({
    columns = list(object({
      name = string
      type = string
    }))
  }))
}
