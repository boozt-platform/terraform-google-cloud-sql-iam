# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

variable "connection_name" {
  type        = string
  description = "The Cloud SQL instance connection name, in the form \"project:region:instance\"."
}

variable "admin_username" {
  type        = string
  description = "Admin user name used to connect to the instance and manage grants."
  sensitive   = true
}

variable "admin_password" {
  type        = string
  description = "Admin password (or a short-lived OAuth2 access token when enable_iam is true)."
  sensitive   = true
}
