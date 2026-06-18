# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

locals {
  db_name         = split(":", var.connection_name)[2]
  user_name       = split("@", var.user)[0]
  full_privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "RELOAD", "SHUTDOWN", "PROCESS", "REFERENCES", "INDEX", "ALTER", "SHOW DATABASES", "CREATE TEMPORARY TABLES", "LOCK TABLES", "EXECUTE", "REPLICATION SLAVE", "REPLICATION CLIENT", "CREATE VIEW", "SHOW VIEW", "CREATE ROUTINE", "ALTER ROUTINE", "CREATE USER", "EVENT", "TRIGGER", "CREATE TABLESPACE", "SHOW_ROUTINE", "SET_USER_ID"]
  is_superuser    = nonsensitive(local.user_name == var.admin_username)
}

resource "google_sql_user" "iam_group_user" {
  name     = var.user
  instance = local.db_name
  type     = var.type
}

resource "mysql_grant" "instance_grants" {
  for_each   = !local.is_superuser && length(var.grants) > 0 ? var.grants : {}
  user       = local.user_name
  depends_on = [google_sql_user.iam_group_user]
  host       = "%"
  database   = each.key
  privileges = each.value
  grant      = false

  lifecycle {
    precondition {
      condition     = !(var.type == "CLOUD_IAM_USER" && each.key == "*")
      error_message = "CLOUD_IAM_USER '${var.user}' must not use wildcard '*' as database name in grants. Specify explicit database names instead."
    }
  }
}

resource "mysql_grant" "instance_table_grants" {
  for_each   = !local.is_superuser && length(var.table_grants) > 0 ? var.table_grants : {}
  user       = local.user_name
  depends_on = [google_sql_user.iam_group_user]
  host       = "%"
  database   = split(".", each.key)[0]
  table      = split(".", each.key)[1]
  privileges = each.value
  grant      = false

  lifecycle {
    precondition {
      condition     = !(var.type == "CLOUD_IAM_USER" && split(".", each.key)[0] == "*")
      error_message = "CLOUD_IAM_USER '${var.user}' must not use wildcard '*' as database name in table_grants. Specify explicit database names instead."
    }
  }
}

resource "mysql_grant" "instance_roles" {
  for_each   = !local.is_superuser && length(var.roles) > 0 ? var.roles : {}
  user       = local.user_name
  depends_on = [google_sql_user.iam_group_user]
  host       = "%"
  database   = each.key
  roles      = each.value
  grant      = false
}

resource "mysql_grant" "instance_superuser_role" {
  count      = local.is_superuser ? 1 : 0
  user       = local.user_name
  depends_on = [google_sql_user.iam_group_user]
  host       = "%"
  database   = "*"
  roles      = ["cloudsqlsuperuser"]
  grant      = true
}

resource "mysql_grant" "instance_superuser_grants" {
  count      = local.is_superuser ? 1 : 0
  user       = local.user_name
  depends_on = [google_sql_user.iam_group_user]
  host       = "%"
  database   = "*"
  privileges = local.full_privileges
  grant      = true
}
