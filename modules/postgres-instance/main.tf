# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

locals {
  db_name = split(":", var.connection_name)[2]

  /**
   * Cloud SQL PostgreSQL IAM login role names (see
   * https://cloud.google.com/sql/docs/postgres/iam-logins):
   *   - IAM user / group  -> the full email address
   *   - service account   -> the email WITHOUT the ".gserviceaccount.com" suffix
   * This differs from MySQL, where the local part of the email is used.
   */
  user_name = var.type == "CLOUD_IAM_SERVICE_ACCOUNT" ? replace(var.user, ".gserviceaccount.com", "") : var.user

  is_superuser = nonsensitive(local.user_name == var.admin_username)

  /**
   * Expand "database.table" or "database.schema.table" keys into a normalised
   * object so each grant resource has explicit database / schema / table parts.
   * Two-part keys assume the configurable default schema (defaults to "public").
   */
  table_grant_entries = {
    for key, privileges in var.table_grants :
    key => {
      database   = split(".", key)[0]
      schema     = length(split(".", key)) == 3 ? split(".", key)[1] : var.default_schema
      table      = length(split(".", key)) == 3 ? split(".", key)[2] : split(".", key)[1]
      privileges = privileges
    }
  }

  /**
   * Expand "database" or "database.schema" keys into explicit database / schema
   * parts. Single-part keys assume the configurable default schema (defaults to
   * "public"). Used for schema-level privileges (CREATE / USAGE).
   */
  schema_grant_entries = {
    for key, privileges in var.schema_grants :
    key => {
      database   = split(".", key)[0]
      schema     = length(split(".", key)) == 2 ? split(".", key)[1] : var.default_schema
      privileges = privileges
    }
  }
}

resource "google_sql_user" "iam_group_user" {
  name     = local.user_name
  instance = local.db_name
  type     = var.type
}

/**
 * Database-level grants. For PostgreSQL these are expressed as table grants on
 * all tables of the (default/public) schema of the target database, mirroring
 * the MySQL "all tables in this database" semantics. CONNECT on the database is
 * granted implicitly by Cloud SQL when the IAM user is created.
 */
resource "postgresql_grant" "instance_grants" {
  for_each    = !local.is_superuser && length(var.grants) > 0 ? var.grants : {}
  role        = local.user_name
  depends_on  = [google_sql_user.iam_group_user]
  database    = each.key
  schema      = var.default_schema
  object_type = "table"
  objects     = [] // empty == all tables of the schema
  privileges  = each.value

  lifecycle {
    precondition {
      condition     = !(var.type == "CLOUD_IAM_USER" && each.key == "*")
      error_message = "CLOUD_IAM_USER '${var.user}' must not use wildcard '*' as database name in grants. Specify explicit database names instead."
    }
  }
}

resource "postgresql_grant" "instance_table_grants" {
  for_each    = !local.is_superuser && length(local.table_grant_entries) > 0 ? local.table_grant_entries : {}
  role        = local.user_name
  depends_on  = [google_sql_user.iam_group_user]
  database    = each.value.database
  schema      = each.value.schema
  object_type = "table"
  objects     = [each.value.table]
  privileges  = each.value.privileges

  lifecycle {
    precondition {
      condition     = !(var.type == "CLOUD_IAM_USER" && each.value.database == "*")
      error_message = "CLOUD_IAM_USER '${var.user}' must not use wildcard '*' as database name in table_grants. Specify explicit database names instead."
    }
  }
}

/**
 * Schema-level grants (e.g. CREATE / USAGE on a schema). Needed for users that
 * run migrations: since PostgreSQL 15 the CREATE privilege on the "public"
 * schema is no longer granted to PUBLIC by default, so migration users need an
 * explicit `GRANT CREATE ON SCHEMA public`.
 */
resource "postgresql_grant" "instance_schema_grants" {
  for_each    = !local.is_superuser && length(local.schema_grant_entries) > 0 ? local.schema_grant_entries : {}
  role        = local.user_name
  depends_on  = [google_sql_user.iam_group_user]
  database    = each.value.database
  schema      = each.value.schema
  object_type = "schema"
  privileges  = each.value.privileges

  lifecycle {
    precondition {
      condition     = !(var.type == "CLOUD_IAM_USER" && each.value.database == "*")
      error_message = "CLOUD_IAM_USER '${var.user}' must not use wildcard '*' as database name in schema_grants. Specify explicit database names instead."
    }
  }
}

/**
 * Role memberships. The map key (database) is not used by PostgreSQL role
 * membership (it is cluster-wide), but the input shape is kept identical to the
 * MySQL sub-module so module usage is engine-agnostic. We flatten to unique
 * (role) pairs so the same role is only granted once even if listed per-db.
 */
locals {
  role_memberships = !local.is_superuser ? toset(flatten([for db, roles in var.roles : roles])) : toset([])
}

resource "postgresql_grant_role" "instance_roles" {
  for_each   = local.role_memberships
  depends_on = [google_sql_user.iam_group_user]
  role       = local.user_name
  grant_role = each.value
}

/**
 * Superuser branch (user matches the instance admin). On Cloud SQL PostgreSQL
 * the elevated role is "cloudsqlsuperuser".
 */
resource "postgresql_grant_role" "instance_superuser_role" {
  count             = local.is_superuser ? 1 : 0
  depends_on        = [google_sql_user.iam_group_user]
  role              = local.user_name
  grant_role        = "cloudsqlsuperuser"
  with_admin_option = true
}
