# =============================================================================
# MÓDULO: DATABASE
# =============================================================================
# Este módulo crea la estructura base de datos en Snowflake para un dominio
# de negocio específico.
#
# Un "Database" en Snowflake es el contenedor de más alto nivel para tus datos.
# Dentro de él vivirán los Schemas, y dentro de los Schemas las Tablas.
#
# APRENDE MÁS: https://docs.snowflake.com/en/sql-reference/sql/create-database
# =============================================================================

locals {
  # Nombre de la base de datos siguiendo convención: <DOMINIO>_<AMBIENTE>
  database_name = "${var.dominio}_${var.ambiente}"
}

# -----------------------------------------------------------------------------
# DATABASE
# -----------------------------------------------------------------------------
# Qué hace: Crea una base de datos en Snowflake.
# Por qué: Es el contenedor raíz para schemas y tablas del dominio.
# Sin esto: No podrías crear schemas ni tablas para este dominio en el ambiente.
# -----------------------------------------------------------------------------
resource "snowflake_database" "this" {
  name                        = local.database_name
  comment                     = var.comment
  data_retention_time_in_days  = var.data_retention_time_in_days
}

# -----------------------------------------------------------------------------
# SCHEMA
# -----------------------------------------------------------------------------
# Qué hace: Crea un schema dentro de la base de datos (ej. FINANCE, CUSTOMERS).
# Por qué: Agrupa objetos relacionados; evita usar PUBLIC que es poco descriptivo.
# Sin esto: Tendrías que usar el schema PUBLIC por defecto, menos claro para negocio.
# -----------------------------------------------------------------------------
resource "snowflake_schema" "this" {
  database = snowflake_database.this.name
  name     = var.schema_name
  comment  = "Schema ${var.schema_name} en ${local.database_name} - Onboarding"
}

# -----------------------------------------------------------------------------
# TABLAS DEL DOMINIO
# -----------------------------------------------------------------------------
# Cada dominio tiene sus propias tablas. Se definen en un mapa para poder
# iterar y mantener una sola fuente de verdad. Las columnas se definen
# según el estándar del proyecto (ver variables tables_config).
# -----------------------------------------------------------------------------

resource "snowflake_table" "tables" {
  for_each = var.tables_config

  database = snowflake_database.this.name
  schema   = snowflake_schema.this.name
  name     = each.key

  dynamic "column" {
    for_each = each.value.columns
    content {
      name = column.value.name
      type = column.value.type
    }
  }

  comment = "Tabla ${each.key} - ${local.database_name}.${var.schema_name}"
}
