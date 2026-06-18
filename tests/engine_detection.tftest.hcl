# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT
#
# Tests for the engine auto-detection logic: the module reads the instance's
# database_version and routes users to the MySQL or PostgreSQL sub-module
# accordingly.

mock_provider "google" {}
mock_provider "mysql" {}
mock_provider "postgresql" {}

variables {
  configuration = {
    connection_name = "project:region:instance"
    admin_username  = "admin"
    admin_password  = "password"
  }
  user_grants = [
    {
      email  = "user1@example.com"
      grants = { "my_database" = ["SELECT"] }
    }
  ]
}

run "detects_mysql_engine" {
  command = plan

  override_data {
    target = data.google_sql_database_instance.this
    values = {
      database_version = "MYSQL_8_0"
    }
  }

  assert {
    condition     = output.engine == "mysql"
    error_message = "Expected engine to be detected as mysql for MYSQL_8_0"
  }

  assert {
    condition     = length(output.mysql_user_names) == 1 && length(output.postgres_user_names) == 0
    error_message = "Expected the user to be routed to the MySQL sub-module only"
  }
}

run "detects_postgres_engine" {
  command = plan

  override_data {
    target = data.google_sql_database_instance.this
    values = {
      database_version = "POSTGRES_15"
    }
  }

  assert {
    condition     = output.engine == "postgres"
    error_message = "Expected engine to be detected as postgres for POSTGRES_15"
  }

  assert {
    condition     = length(output.postgres_user_names) == 1 && length(output.mysql_user_names) == 0
    error_message = "Expected the user to be routed to the PostgreSQL sub-module only"
  }
}
