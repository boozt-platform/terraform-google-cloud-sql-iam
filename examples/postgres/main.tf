# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

# Example: manage users and grants on a Cloud SQL *PostgreSQL* instance.
#
# Usage is identical to the MySQL example; the module auto-detects the engine
# from the instance's database_version. Supply PostgreSQL-valid privilege names
# (e.g. SELECT, INSERT, USAGE, CREATE, EXECUTE) for PostgreSQL instances.

module "cloud_sql_iam" {
  # This example uses a local source so it always validates against the code in
  # this repository. When consuming the published module, use the registry
  # source and a version constraint instead, e.g.:
  #
  #   source  = "boozt-platform/cloud-sql-iam/google"
  #   version = "~> 1.1"
  source = "../../"

  configuration = {
    connection_name = var.connection_name
    admin_username  = var.admin_username
    admin_password  = var.admin_password
    enable_iam      = false
  }

  user_grants = [
    {
      email     = "my-service-account@my-project.iam.gserviceaccount.com"
      user_type = "CLOUD_IAM_SERVICE_ACCOUNT"
      grants    = { "*" = ["SELECT", "INSERT", "UPDATE", "DELETE"] }
      # Schema-level privileges (PostgreSQL only). Needed for migration users
      # since PostgreSQL 15 no longer grants CREATE on schema "public" to PUBLIC.
      schema_grants = { "my_application_db.public" = ["CREATE", "USAGE"] }
    },
    {
      # CLOUD_IAM_USER (default) must specify explicit database names.
      email = "user1@example.com"
      grants = {
        "my_application_db" = ["SELECT", "INSERT", "UPDATE", "DELETE"]
        "reporting_db"      = ["SELECT"]
      }
      roles = { "*" = ["fulldevuser"] }
    },
    {
      # Table-level grants: "database.table" (assumes the public schema) or
      # "database.schema.table" (explicit schema).
      email = "restricted-service@example.com"
      table_grants = {
        "my_application_db.users"          = ["SELECT"]
        "my_application_db.sales.invoices" = ["SELECT", "INSERT", "UPDATE"]
      }
    }
  ]
}
