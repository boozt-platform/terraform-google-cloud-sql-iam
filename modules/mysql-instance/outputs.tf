# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

output "user_name" {
  description = "The in-database MySQL user name (the local part of the email)."
  value       = local.user_name
}

output "sql_user" {
  description = "The google_sql_user resource created for this user."
  value       = google_sql_user.iam_group_user
  sensitive   = true
}
