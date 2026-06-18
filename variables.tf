# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

variable "user_grants" {
  type = list(object({
    email         = string
    user_type     = optional(string, "CLOUD_IAM_USER")
    grants        = optional(map(list(string)), {})
    table_grants  = optional(map(list(string)), {})
    schema_grants = optional(map(list(string)), {})
    roles         = optional(map(list(string)), {})
  }))
  description = "Map of grants for each users"

  validation {
    condition     = length(var.user_grants) == length(distinct([for u in var.user_grants : u.email]))
    error_message = "Duplicate users detected in user_grants. Each email must be unique."
  }

  validation {
    condition = alltrue([
      for u in var.user_grants :
      !contains(keys(u.grants), "*") if u.user_type == "CLOUD_IAM_USER"
    ])
    error_message = "CLOUD_IAM_USER users must specify explicit database names in grants. The wildcard '*' is not allowed. Use specific database names instead (e.g., { \"my_database\" = [\"SELECT\", \"INSERT\"] })."
  }

  validation {
    condition = alltrue([
      for u in var.user_grants :
      alltrue([
        for key in keys(u.table_grants) :
        contains([2, 3], length(split(".", key))) ? alltrue([for part in split(".", key) : length(part) > 0]) : false
      ])
    ])
    error_message = "Each key in table_grants must be in the format \"database.table\" (MySQL/PostgreSQL) or \"database.schema.table\" (PostgreSQL) with no empty parts (e.g., { \"my_database.my_table\" = [\"SELECT\", \"INSERT\"] })."
  }

  validation {
    condition = alltrue([
      for u in var.user_grants :
      !anytrue([for key in keys(u.table_grants) : split(".", key)[0] == "*"]) if u.user_type == "CLOUD_IAM_USER"
    ])
    error_message = "CLOUD_IAM_USER users must specify explicit database names in table_grants. The wildcard '*' is not allowed as the database part."
  }

  validation {
    condition = alltrue([
      for u in var.user_grants :
      alltrue([
        for key in keys(u.schema_grants) :
        contains([1, 2], length(split(".", key))) && alltrue([for part in split(".", key) : length(part) > 0])
      ])
    ])
    error_message = "Each key in schema_grants must be in the format \"database\" or \"database.schema\" with no empty parts (e.g., { \"my_database.public\" = [\"CREATE\"] }). PostgreSQL only."
  }

  validation {
    condition = alltrue([
      for u in var.user_grants :
      !anytrue([for key in keys(u.schema_grants) : split(".", key)[0] == "*"]) if u.user_type == "CLOUD_IAM_USER"
    ])
    error_message = "CLOUD_IAM_USER users must specify explicit database names in schema_grants. The wildcard '*' is not allowed as the database part."
  }
}

variable "configuration" {
  type = object({
    connection_name = string
    admin_username  = string
    admin_password  = string
    enable_iam      = optional(bool, false)
  })
  default = {
    connection_name = null
    admin_username  = null
    admin_password  = null
    enable_iam      = false
  }
  description = "Username and password for Cloud SQL instance admin user"
  sensitive   = true
}

variable "auth_type" {
  type        = string
  description = "Sets the authentication plugin, it can be one of the following: `native` or `cleartext`"
  default     = "native"
}
