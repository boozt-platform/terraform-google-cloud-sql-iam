# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.53, < 8.0"
    }

    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
  }
}

# - PREDEFINED PROVIDER CONNECTIONS -
#
# This module declares its own provider configurations. This is required so the
# root module can fan out to a per-user sub-module with for_each (a module that
# defines its own provider blocks is not compatible with for_each/count/
# depends_on when the provider is configured by the child module itself).
# See https://developer.hashicorp.com/terraform/language/modules/develop/providers
#
# Both the MySQL and PostgreSQL providers are declared, but each engine's
# resources are gated on the auto-detected database engine (see main.tf). Both
# providers connect lazily (only when a resource performs an operation), so the
# provider for the unused engine never opens a connection.
#
# NOTE (roadmap): declaring providers inside the module is generally discouraged
# for registry modules because it prevents callers from supplying their own
# provider configuration. A future major version may move provider configuration
# to the caller. See the "Known limitations" section in the README.

provider "mysql" {
  alias                       = "cloudsql"
  username                    = var.configuration.admin_username
  password                    = var.configuration.admin_password
  endpoint                    = "cloudsql://${var.configuration.connection_name}"
  authentication_plugin       = var.auth_type
  iam_database_authentication = var.configuration.enable_iam
}

provider "postgresql" {
  alias     = "cloudsql"
  scheme    = "gcppostgres"
  host      = var.configuration.connection_name
  username  = var.configuration.admin_username
  password  = var.configuration.admin_password
  superuser = false # Cloud SQL admin user is not a real PostgreSQL superuser
  sslmode   = "disable"
}
