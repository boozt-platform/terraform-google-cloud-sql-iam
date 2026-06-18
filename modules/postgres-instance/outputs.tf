# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

output "user_name" {
  description = <<-EOT
    The in-database PostgreSQL role name. For CLOUD_IAM_SERVICE_ACCOUNT this is
    the email without the ".gserviceaccount.com" suffix; otherwise the full
    email.
  EOT
  value       = local.user_name
}

output "sql_user" {
  description = "The google_sql_user resource created for this user."
  value       = google_sql_user.iam_group_user
  sensitive   = true
}
