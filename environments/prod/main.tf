# =============================================================================
# ENVIRONMENT: PROD
# =============================================================================
# En PROD los functional roles tienen permisos más restrictivos: ANALYST solo
# lectura, ENGINEER escritura, ADMIN todo; READONLY solo OR_READ en PROD.
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

provider "snowflake" {
  account  = var.snowflake_account
  region   = var.snowflake_region
  username = var.snowflake_user
  password = var.snowflake_password
  role     = var.snowflake_role
}

locals {
  ambiente = "PROD"
  erp_tables = {
    INVOICES = { columns = [{ name = "ID", type = "NUMBER(38,0)" }, { name = "INVOICE_NUMBER", type = "VARCHAR(50)" }, { name = "AMOUNT", type = "NUMBER(18,2)" }, { name = "CURRENCY", type = "VARCHAR(3)" }, { name = "STATUS", type = "VARCHAR(20)" }, { name = "CREATED_AT", type = "TIMESTAMP_NTZ" }] }
    COST_CENTERS = { columns = [{ name = "ID", type = "NUMBER(38,0)" }, { name = "CODE", type = "VARCHAR(20)" }, { name = "NAME", type = "VARCHAR(100)" }, { name = "DEPARTMENT", type = "VARCHAR(50)" }, { name = "BUDGET", type = "NUMBER(18,2)" }, { name = "ACTIVE", type = "BOOLEAN" }] }
  }
  crm_tables = {
    CONTACTS = { columns = [{ name = "ID", type = "NUMBER(38,0)" }, { name = "FIRST_NAME", type = "VARCHAR(50)" }, { name = "LAST_NAME", type = "VARCHAR(50)" }, { name = "EMAIL", type = "VARCHAR(100)" }, { name = "PHONE", type = "VARCHAR(20)" }, { name = "COUNTRY", type = "VARCHAR(50)" }, { name = "CREATED_AT", type = "TIMESTAMP_NTZ" }] }
    OPPORTUNITIES = { columns = [{ name = "ID", type = "NUMBER(38,0)" }, { name = "NAME", type = "VARCHAR(200)" }, { name = "AMOUNT", type = "NUMBER(18,2)" }, { name = "STAGE", type = "VARCHAR(50)" }, { name = "CLOSE_DATE", type = "DATE" }, { name = "CONTACT_ID", type = "NUMBER(38,0)" }] }
  }
  scm_tables = {
    SHIPMENTS = { columns = [{ name = "ID", type = "NUMBER(38,0)" }, { name = "TRACKING_NUMBER", type = "VARCHAR(50)" }, { name = "ORIGIN", type = "VARCHAR(100)" }, { name = "DESTINATION", type = "VARCHAR(100)" }, { name = "STATUS", type = "VARCHAR(30)" }, { name = "SHIPPED_AT", type = "TIMESTAMP_NTZ" }] }
    SUPPLIERS = { columns = [{ name = "ID", type = "NUMBER(38,0)" }, { name = "NAME", type = "VARCHAR(100)" }, { name = "COUNTRY", type = "VARCHAR(50)" }, { name = "CONTACT_EMAIL", type = "VARCHAR(100)" }, { name = "RATING", type = "NUMBER(2,1)" }, { name = "ACTIVE", type = "BOOLEAN" }] }
  }
  # En PROD: ANALYST solo lectura, ENGINEER escritura, ADMIN todo, READONLY solo lectura
  functional_roles_prod = {
    FR_DATA_ANALYST  = ["OR_READ_ERP_FINANCE_PROD", "OR_READ_CRM_CUSTOMERS_PROD", "OR_READ_SCM_LOGISTICS_PROD"]
    FR_DATA_ENGINEER = ["OR_WRITE_ERP_FINANCE_PROD", "OR_WRITE_CRM_CUSTOMERS_PROD", "OR_WRITE_SCM_LOGISTICS_PROD"]
    FR_DATA_ADMIN    = ["OR_ADMIN_ERP_FINANCE_PROD", "OR_ADMIN_CRM_CUSTOMERS_PROD", "OR_ADMIN_SCM_LOGISTICS_PROD"]
    FR_READONLY      = ["OR_READ_ERP_FINANCE_PROD", "OR_READ_CRM_CUSTOMERS_PROD", "OR_READ_SCM_LOGISTICS_PROD"]
  }
  warehouse_config = {
    INGESTION = { size = "X-SMALL", auto_suspend = 60, comment = "Cargas ETL - Onboarding" }
    ANALYTICS =  { size = "X-SMALL", auto_suspend = 120, comment = "Consultas y dashboards - Onboarding" }
    ADMIN     =  { size = "X-SMALL", auto_suspend = 30, comment = "Tareas administrativas - Onboarding" }
  }
}

module "database_erp" {
  source         = "../../modules/database"
  dominio        = "ERP"
  ambiente       = local.ambiente
  schema_name    = "FINANCE"
  comment        = "ERP - Finanzas - Onboarding"
  tables_config  = local.erp_tables
}

module "database_crm" {
  source         = "../../modules/database"
  dominio        = "CRM"
  ambiente       = local.ambiente
  schema_name    = "CUSTOMERS"
  comment        = "CRM - Clientes - Onboarding"
  tables_config  = local.crm_tables
}

module "database_scm" {
  source         = "../../modules/database"
  dominio        = "SCM"
  ambiente       = local.ambiente
  schema_name    = "LOGISTICS"
  comment        = "SCM - Logística - Onboarding"
  tables_config  = local.scm_tables
}

module "warehouse" {
  source      = "../../modules/warehouse"
  ambiente    = local.ambiente
  warehouses  = local.warehouse_config
}

module "security" {
  source           = "../../modules/security"
  ambiente         = local.ambiente
  password_history = 5
  max_retries      = 5
  min_length       = 12
}

module "rbac" {
  source          = "../../modules/rbac"
  ambiente        = local.ambiente
  schemas = [
    { database_name = module.database_erp.database_name, schema_name = module.database_erp.schema_name, dominio = "ERP", table_names = module.database_erp.table_names },
    { database_name = module.database_crm.database_name, schema_name = module.database_crm.schema_name, dominio = "CRM", table_names = module.database_crm.table_names },
    { database_name = module.database_scm.database_name, schema_name = module.database_scm.schema_name, dominio = "SCM", table_names = module.database_scm.table_names }
  ]
  warehouse_names  = module.warehouse.warehouse_names
  functional_roles  = local.functional_roles_prod
  users = [
    { login_name = "U_ANA_GARCIA", default_role = "FR_DATA_ANALYST", default_warehouse = module.warehouse.warehouse_names["ANALYTICS"], comment = "Onboarding: Analista - ejemplo" },
    { login_name = "U_CARLOS_LOPEZ", default_role = "FR_DATA_ENGINEER", default_warehouse = module.warehouse.warehouse_names["INGESTION"], comment = "Onboarding: Ingeniero - ejemplo" },
    { login_name = "U_MARIA_TORRES", default_role = "FR_DATA_ADMIN", default_warehouse = module.warehouse.warehouse_names["ADMIN"], comment = "Onboarding: Admin - ejemplo" },
    { login_name = "U_PEDRO_RAMIREZ", default_role = "FR_READONLY", default_warehouse = module.warehouse.warehouse_names["ANALYTICS"], comment = "Onboarding: Solo lectura - ejemplo" }
  ]
}
