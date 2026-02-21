# =============================================================================
# MÓDULO WAREHOUSE - VARIABLES
# =============================================================================
# Los warehouses son los "motores" que consumen créditos al ejecutar queries.
# Este módulo crea uno o varios por ambiente con distintos propósitos.
# =============================================================================

variable "ambiente" {
  description = "Ambiente (DEV, UAT, PROD). Se usa en el nombre: WH_<PROPOSITO>_<AMBIENTE>."
  type        = string

  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.ambiente)
    error_message = "ambiente debe ser uno de: DEV, UAT, PROD."
  }
}

variable "warehouses" {
  description = "Mapa de warehouses a crear. Key = propósito (INGESTION, ANALYTICS, ADMIN), value = tamaño, auto_suspend segundos, comment."
  type = map(object({
    size          = string
    auto_suspend  = number
    comment       = string
  }))
}
