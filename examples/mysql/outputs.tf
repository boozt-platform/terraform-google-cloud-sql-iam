# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

output "engine" {
  description = "The database engine detected by the module (expected: mysql)."
  value       = module.cloud_sql_iam.engine
}

output "managed_users" {
  description = "The list of user emails managed on the instance."
  value       = module.cloud_sql_iam.managed_users
}
