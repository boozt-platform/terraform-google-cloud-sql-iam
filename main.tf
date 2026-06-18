# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

/**
 * Auto-detect the database engine (MySQL vs PostgreSQL) from the instance's
 * database_version so callers never have to declare it. The connection_name is
 * "project:region:instance"; the data source needs the project and instance
 * name.
 */
data "google_sql_database_instance" "this" {
  project = split(":", var.configuration.connection_name)[0]
  name    = split(":", var.configuration.connection_name)[2]
}

locals {
  engine = startswith(data.google_sql_database_instance.this.database_version, "POSTGRES") ? "postgres" : "mysql"

  mysql_user_grants    = local.engine == "mysql" ? tomap({ for u in var.user_grants : u.email => u }) : {}
  postgres_user_grants = local.engine == "postgres" ? tomap({ for u in var.user_grants : u.email => u }) : {}
}

/**
 * IMPORTANT: Make sure the database exists before granting permissions
 */
module "mysql_permissions" {
  source = "./modules/mysql-instance/"

  for_each = local.mysql_user_grants

  user            = each.key
  grants          = each.value.grants
  table_grants    = each.value.table_grants
  roles           = each.value.roles
  type            = each.value.user_type
  connection_name = var.configuration.connection_name
  admin_username  = var.configuration.admin_username
  providers = {
    mysql = mysql.cloudsql
  }

}

module "postgres_permissions" {
  source = "./modules/postgres-instance/"

  for_each = local.postgres_user_grants

  user            = each.key
  grants          = each.value.grants
  table_grants    = each.value.table_grants
  schema_grants   = each.value.schema_grants
  roles           = each.value.roles
  type            = each.value.user_type
  connection_name = var.configuration.connection_name
  admin_username  = var.configuration.admin_username
  providers = {
    postgresql = postgresql.cloudsql
  }

}
