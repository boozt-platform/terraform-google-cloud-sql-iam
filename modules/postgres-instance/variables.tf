# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

variable "user" {
  type        = string
  description = "Single user to create in the instance"
  default     = null

  validation {
    condition     = length(regexall("^.*@.*$", var.user)) == 1
    error_message = "Include your email user name"
  }
}

variable "type" {
  type    = string
  default = "CLOUD_IAM_USER"
}

variable "grants" {
  type        = map(list(string))
  description = "List of grants to assign to the user for a specific database"
  default     = {}
}

variable "table_grants" {
  type        = map(list(string))
  description = "List of grants to assign to the user for a specific database table. Keys must be in the format 'database.table' or 'database.schema.table'."
  default     = {}
}

variable "schema_grants" {
  type        = map(list(string))
  description = "Schema-level privileges (e.g. CREATE, USAGE) to assign to the user. Keys must be in the format 'database' (assumes the default schema) or 'database.schema'."
  default     = {}
}

variable "roles" {
  type        = map(list(string))
  description = "List of roles to assign to the user for a specific database"
  default     = {}
}

variable "connection_name" {
  type        = string
  description = "Single Cloud SQL instance connection name"
  default     = null
}

variable "admin_username" {
  type        = string
  description = "user name for the admin account"
  default     = null
}

variable "default_schema" {
  type        = string
  description = "Schema assumed for two-part 'database.table' table_grants keys"
  default     = "public"
}
