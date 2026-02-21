# =============================================================================
# MÓDULO: WAREHOUSE
# =============================================================================
# Crea warehouses (almacenes de cómputo) en Snowflake. Cada warehouse es
# un cluster que ejecuta queries; el tamaño y auto_suspend afectan coste
# y rendimiento. Por convención: WH_<PROPOSITO>_<AMBIENTE>.
#
# APRENDE MÁS: https://docs.snowflake.com/en/user-guide/warehouses-overview
# =============================================================================

resource "snowflake_warehouse" "this" {
  for_each = var.warehouses

  name            = "WH_${each.key}_${var.ambiente}"
  warehouse_size  = each.value.size
  auto_suspend    = each.value.auto_suspend
  comment         = each.value.comment
  initially_suspended = true
}
