# =============================================================================
# MÓDULO: RBAC (Role-Based Access Control)
# =============================================================================
# Implementa el modelo de roles jerárquico: Object Roles (pegados a cada schema)
# -> Functional Roles (agrupan object roles por perfil) -> Usuarios.
#
# APRENDE MÁS: https://docs.snowflake.com/en/user-guide/security-access-control
# =============================================================================

locals {
  # Clave única por schema para iterar
  schema_keys = { for idx, s in var.schemas : "${s.dominio}_${s.schema_name}" => s }
}

# -----------------------------------------------------------------------------
# OBJECT ROLES (por cada schema: READ, WRITE, ADMIN)
# -----------------------------------------------------------------------------
# Qué hace: Crea tres roles por schema (OR_READ_*, OR_WRITE_*, OR_ADMIN_*).
# Por qué: Separar permisos por nivel evita dar más acceso del necesario.
# Sin esto: Tendrías que usar un solo role por schema o roles a nivel cuenta.
# -----------------------------------------------------------------------------
resource "snowflake_account_role" "object_read" {
  for_each = local.schema_keys

  name    = "OR_READ_${each.value.dominio}_${each.value.schema_name}_${var.ambiente}"
  comment = "Lectura (SELECT) en ${each.value.database_name}.${each.value.schema_name}"
}

resource "snowflake_account_role" "object_write" {
  for_each = local.schema_keys

  name    = "OR_WRITE_${each.value.dominio}_${each.value.schema_name}_${var.ambiente}"
  comment = "Lectura y escritura en ${each.value.database_name}.${each.value.schema_name}"
}

resource "snowflake_account_role" "object_admin" {
  for_each = local.schema_keys

  name    = "OR_ADMIN_${each.value.dominio}_${each.value.schema_name}_${var.ambiente}"
  comment = "Admin (DDL + datos) en ${each.value.database_name}.${each.value.schema_name}"
}

# -----------------------------------------------------------------------------
# GRANTS: USAGE en database y schema (todos los object roles)
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "read_usage_db" {
  for_each = local.schema_keys

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.object_read[each.key].name
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.database_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "read_usage_schema" {
  for_each = local.schema_keys

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.object_read[each.key].name
  on_schema {
    schema_name = "${each.value.database_name}.${each.value.schema_name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "write_usage_db" {
  for_each = local.schema_keys

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.object_write[each.key].name
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.database_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "write_usage_schema" {
  for_each = local.schema_keys

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.object_write[each.key].name
  on_schema {
    schema_name = "${each.value.database_name}.${each.value.schema_name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "admin_usage_db" {
  for_each = local.schema_keys

  privileges        = ["USAGE", "MODIFY"]
  account_role_name = snowflake_account_role.object_admin[each.key].name
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.database_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "admin_usage_schema" {
  for_each = local.schema_keys

  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE"]
  account_role_name = snowflake_account_role.object_admin[each.key].name
  on_schema {
    schema_name = "${each.value.database_name}.${each.value.schema_name}"
  }
}

# -----------------------------------------------------------------------------
# GRANTS: SELECT en tablas (READ); SELECT+INSERT+UPDATE+DELETE (WRITE/ADMIN)
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "read_select_tables" {
  for_each = { for pair in flatten([for k, s in local.schema_keys : [for t in s.table_names : { key = "${k}_${t}", schema_key = k, table = t, schema = s }]]) : pair.key => pair }

  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.object_read[each.value.schema_key].name
  on_schema_object {
    object_type = "TABLE"
    object_name = "${each.value.schema.database_name}.${each.value.schema.schema_name}.${each.value.table}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "write_dml_tables" {
  for_each = { for pair in flatten([for k, s in local.schema_keys : [for t in s.table_names : { key = "${k}_${t}", schema_key = k, table = t, schema = s }]]) : pair.key => pair }

  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE"]
  account_role_name = snowflake_account_role.object_write[each.value.schema_key].name
  on_schema_object {
    object_type = "TABLE"
    object_name = "${each.value.schema.database_name}.${each.value.schema.schema_name}.${each.value.table}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "admin_dml_tables" {
  for_each = { for pair in flatten([for k, s in local.schema_keys : [for t in s.table_names : { key = "${k}_${t}", schema_key = k, table = t, schema = s }]]) : pair.key => pair }

  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE"]
  account_role_name = snowflake_account_role.object_admin[each.value.schema_key].name
  on_schema_object {
    object_type = "TABLE"
    object_name = "${each.value.schema.database_name}.${each.value.schema.schema_name}.${each.value.table}"
  }
}

# WRITE y ADMIN heredan de READ (opcional en Snowflake: puedes dar solo los extras y no READ; aquí damos todos los DML explícitos)
# OR_ADMIN necesita USAGE en warehouse
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "admin_usage_warehouse" {
  for_each = local.schema_keys

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.object_admin[each.key].name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouse_names["ADMIN"]
  }
}

# -----------------------------------------------------------------------------
# HERENCIA: Object role READ -> WRITE -> ADMIN (WRITE incluye READ; ADMIN incluye WRITE)
# En Snowflake se modela dando el role inferior al superior: GRANT OR_READ_* TO ROLE OR_WRITE_*
# -----------------------------------------------------------------------------
resource "snowflake_grant_account_role" "write_inherits_read" {
  for_each = local.schema_keys

  role_name        = snowflake_account_role.object_write[each.key].name
  parent_role_name = snowflake_account_role.object_read[each.key].name
}

resource "snowflake_grant_account_role" "admin_inherits_write" {
  for_each = local.schema_keys

  role_name        = snowflake_account_role.object_admin[each.key].name
  parent_role_name = snowflake_account_role.object_write[each.key].name
}

# -----------------------------------------------------------------------------
# FUNCTIONAL ROLES (FR_DATA_ANALYST, etc.) — solo si create_functional_roles_and_users = true
# En la misma cuenta, DEV los crea; UAT/PROD los reutilizan.
# -----------------------------------------------------------------------------
resource "snowflake_account_role" "functional" {
  for_each = var.create_functional_roles_and_users ? var.functional_roles : {}

  name    = each.key
  comment = "Functional role - Onboarding: ${each.key}"
}

# Cada functional role recibe los object roles que le correspondan (por nombre)
# parent_role_name = FR_* (por nombre, así funciona aunque el role lo haya creado otro ambiente)
# -----------------------------------------------------------------------------
locals {
  functional_role_grants = flatten([
    for fr_name, or_list in var.functional_roles : [
      for or_name in or_list : { fr = fr_name, parent_role = or_name }
    ]
  ])
}

# En este provider: parent_role_name = role que se OTORGA; role_name = grantee (quien RECIBE).
# Queremos: otorgar object role (OR_*_PROD) al functional role (FR_*).
resource "snowflake_grant_account_role" "functional_inherits_object" {
  for_each = { for idx, g in local.functional_role_grants : "${g.fr}_${g.parent_role}" => g }

  parent_role_name = each.value.parent_role
  role_name        = each.value.fr
}

# -----------------------------------------------------------------------------
# USUARIOS DE EJEMPLO — solo si create_functional_roles_and_users = true
# -----------------------------------------------------------------------------
resource "snowflake_user" "users" {
  for_each = var.create_functional_roles_and_users ? { for u in var.users : u.login_name => u } : {}

  name                 = each.value.login_name
  default_role         = each.value.default_role
  default_warehouse    = each.value.default_warehouse
  must_change_password = true
  comment              = each.value.comment
}

resource "snowflake_grant_account_role" "user_has_functional_role" {
  for_each = var.create_functional_roles_and_users ? { for u in var.users : u.login_name => u } : {}

  role_name = each.value.default_role
  user_name = each.value.login_name
}
