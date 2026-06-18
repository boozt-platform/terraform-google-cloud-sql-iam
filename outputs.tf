# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

output "engine" {
  description = <<-EOT
    The database engine auto-detected from the Cloud SQL instance's
    database_version. Either "mysql" or "postgres".
  EOT
  value       = local.engine
}

output "database_version" {
  description = "The raw database_version reported by the Cloud SQL instance (e.g. \"POSTGRES_15\", \"MYSQL_8_0\")."
  value       = data.google_sql_database_instance.this.database_version
}

output "managed_users" {
  description = "The list of user emails managed by this module on the target instance."
  value       = [for u in var.user_grants : u.email]
}

output "mysql_user_names" {
  description = <<-EOT
    Map of email to the in-database MySQL user name for each managed user.
    Empty when the target instance is PostgreSQL.
  EOT
  value       = { for email, m in module.mysql_permissions : email => m.user_name }
}

output "postgres_user_names" {
  description = <<-EOT
    Map of email to the in-database PostgreSQL role name for each managed user.
    For service accounts this is the email without the ".gserviceaccount.com"
    suffix. Empty when the target instance is MySQL.
  EOT
  value       = { for email, m in module.postgres_permissions : email => m.user_name }
}
