# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

# Example: manage users and grants on a Cloud SQL *MySQL* instance.
#
# The module auto-detects the engine from the instance's database_version, so
# usage is identical for MySQL and PostgreSQL. Supply MySQL-valid privilege
# names for MySQL instances.

module "cloud_sql_iam" {
  source = "../../"

  configuration = {
    connection_name = var.connection_name
    admin_username  = var.admin_username
    admin_password  = var.admin_password
    # Enable for automatic IAM authentication (admin_password must then be a
    # short-lived OAuth2 access token of the connecting identity).
    enable_iam = false
  }

  user_grants = [
    {
      # Service accounts may use the wildcard "*" database.
      email     = "my-service-account@my-project.iam.gserviceaccount.com"
      user_type = "CLOUD_IAM_SERVICE_ACCOUNT"
      grants    = { "*" = ["SELECT", "INSERT", "UPDATE", "DELETE"] }
    },
    {
      # CLOUD_IAM_USER (default) must specify explicit database names.
      email = "user1@example.com"
      grants = {
        "my_application_db" = ["SELECT", "INSERT", "UPDATE", "DELETE"]
        "reporting_db"      = ["SELECT"]
      }
    },
    {
      # Table-level grants for fine-grained access.
      email = "restricted-service@example.com"
      table_grants = {
        "my_application_db.users"  = ["SELECT"]
        "my_application_db.orders" = ["SELECT", "INSERT", "UPDATE"]
      }
    }
  ]
}
