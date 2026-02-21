# =============================================================================
# MÓDULO RBAC - VARIABLES
# =============================================================================
# Define roles jerárquicos (Object Roles -> Functional Roles -> Usuarios)
# y sus privilegios. Todos los nombres siguen la convención del proyecto.
# =============================================================================

variable "ambiente" {
  description = "Ambiente actual (DEV, UAT, PROD) para nombrar object roles."
  type        = string
}

# -----------------------------------------------------------------------------
# Información de schemas (salida de los módulos database)
# -----------------------------------------------------------------------------
# Cada elemento describe un schema donde crearemos OR_READ, OR_WRITE, OR_ADMIN.
# -----------------------------------------------------------------------------
variable "schemas" {
  description = "Lista de schemas: database_name, schema_name, dominio, table_names (lista de nombres de tablas)."
  type = list(object({
    database_name = string
    schema_name   = string
    dominio       = string
    table_names   = list(string)
  }))
}

variable "warehouse_names" {
  description = "Mapa de propósito (INGESTION, ANALYTICS, ADMIN) a nombre del warehouse para OR_ADMIN."
  type        = map(string)
}

# -----------------------------------------------------------------------------
# Functional roles: qué object roles hereda cada uno en este ambiente
# -----------------------------------------------------------------------------
# FR_DATA_ANALYST: OR_READ en PROD, OR_WRITE en DEV/UAT
# FR_DATA_ENGINEER: OR_WRITE en PROD, OR_ADMIN en DEV/UAT
# FR_DATA_ADMIN: OR_ADMIN en todos
# FR_READONLY: OR_READ solo en PROD
# -----------------------------------------------------------------------------
variable "functional_roles" {
  description = "Mapa de nombre functional role -> lista de object role names que hereda (ej. [\"OR_READ_ERP_FINANCE_DEV\"])."
  type        = map(list(string))
}

# -----------------------------------------------------------------------------
# Usuarios de ejemplo: login_name, functional_role, default_warehouse, comment
# -----------------------------------------------------------------------------
variable "users" {
  description = "Lista de usuarios: login_name (ej. U_ANA_GARCIA), default_role (FR_*), default_warehouse (nombre WH_*), comment."
  type = list(object({
    login_name         = string
    default_role       = string
    default_warehouse  = string
    comment            = string
  }))
}
