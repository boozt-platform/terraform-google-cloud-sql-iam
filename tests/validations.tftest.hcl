# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT
#
# Tests for the input validation rules on var.user_grants. These rules are
# evaluated at plan time before any provider connection is made, so the runs
# below use command = plan with mocked providers and assert the expected
# validation failures.

mock_provider "google" {}

# Override the module's provider configurations with inert local connections so
# the test never registers the Cloud SQL (gcppostgres / cloudsql) drivers, which
# would otherwise require Application Default Credentials at configure time.
# Plans run against mocked resources, so no real connection is ever made.
provider "mysql" {
  alias    = "cloudsql"
  endpoint = "localhost:3306"
}

provider "postgresql" {
  alias    = "cloudsql"
  scheme   = "postgres"
  host     = "localhost"
  username = "test"
  password = "test"
}

# The engine-detection data source is read during plan; return a version so the
# valid runs can proceed without a real Cloud SQL instance.
override_data {
  target = data.google_sql_database_instance.this
  values = {
    database_version = "MYSQL_8_0"
  }
}

variables {
  configuration = {
    connection_name = "project:region:instance"
    admin_username  = "admin"
    admin_password  = "password"
  }
}

run "valid_iam_user_with_explicit_databases" {
  command = plan

  variables {
    user_grants = [
      {
        email  = "user1@example.com"
        grants = { "my_database" = ["SELECT", "INSERT"] }
      }
    ]
  }
}

run "valid_service_account_with_wildcard" {
  command = plan

  variables {
    user_grants = [
      {
        email     = "mysa@example.com"
        user_type = "CLOUD_IAM_SERVICE_ACCOUNT"
        grants    = { "*" = ["SELECT", "INSERT"] }
      }
    ]
  }
}

run "invalid_iam_user_with_wildcard" {
  command = plan

  variables {
    user_grants = [
      {
        email  = "user1@example.com"
        grants = { "*" = ["SELECT", "INSERT"] }
      }
    ]
  }

  expect_failures = [var.user_grants]
}

run "valid_mixed_users" {
  command = plan

  variables {
    user_grants = [
      {
        email     = "mysa@example.com"
        user_type = "CLOUD_IAM_SERVICE_ACCOUNT"
        grants    = { "*" = ["SELECT"] }
      },
      {
        email  = "user1@example.com"
        grants = { "my_database" = ["SELECT"] }
      }
    ]
  }
}

run "invalid_duplicate_users" {
  command = plan

  variables {
    user_grants = [
      {
        email  = "dupe@example.com"
        grants = { "db1" = ["SELECT"] }
      },
      {
        email  = "dupe@example.com"
        grants = { "db2" = ["SELECT"] }
      }
    ]
  }

  expect_failures = [var.user_grants]
}

run "valid_iam_user_table_grants" {
  command = plan

  variables {
    user_grants = [
      {
        email = "user1@example.com"
        table_grants = {
          "my_database.users"  = ["SELECT", "INSERT"]
          "my_database.orders" = ["SELECT"]
        }
      }
    ]
  }
}

run "valid_table_grants_with_db_grants" {
  command = plan

  variables {
    user_grants = [
      {
        email        = "user1@example.com"
        grants       = { "my_database" = ["SELECT"] }
        table_grants = { "my_database.users" = ["SELECT", "INSERT"] }
      }
    ]
  }
}

run "invalid_table_grants_format" {
  command = plan

  variables {
    user_grants = [
      {
        email        = "user1@example.com"
        table_grants = { "missing_table" = ["SELECT"] }
      }
    ]
  }

  expect_failures = [var.user_grants]
}

run "invalid_iam_user_table_grants_wildcard" {
  command = plan

  variables {
    user_grants = [
      {
        email        = "user1@example.com"
        table_grants = { "*.users" = ["SELECT"] }
      }
    ]
  }

  expect_failures = [var.user_grants]
}

run "valid_iam_user_no_grants" {
  command = plan

  variables {
    user_grants = [
      {
        email = "user1@example.com"
      }
    ]
  }
}

run "valid_pg_user_schema_table_grants" {
  command = plan

  variables {
    user_grants = [
      {
        email = "user1@example.com"
        table_grants = {
          "my_database.users"          = ["SELECT", "INSERT"]
          "my_database.sales.invoices" = ["SELECT"]
        }
      }
    ]
  }
}

run "invalid_table_grants_too_many_parts" {
  command = plan

  variables {
    user_grants = [
      {
        email        = "user1@example.com"
        table_grants = { "my_database.public.users.extra" = ["SELECT"] }
      }
    ]
  }

  expect_failures = [var.user_grants]
}

run "valid_schema_grants" {
  command = plan

  variables {
    user_grants = [
      {
        email = "user1@example.com"
        schema_grants = {
          "my_database"        = ["CREATE"]
          "my_database.public" = ["CREATE", "USAGE"]
        }
      }
    ]
  }
}

run "invalid_iam_user_schema_grants_wildcard" {
  command = plan

  variables {
    user_grants = [
      {
        email         = "user1@example.com"
        schema_grants = { "*" = ["CREATE"] }
      }
    ]
  }

  expect_failures = [var.user_grants]
}

run "invalid_schema_grants_format" {
  command = plan

  variables {
    user_grants = [
      {
        email         = "user1@example.com"
        schema_grants = { "my_database.public.extra" = ["CREATE"] }
      }
    ]
  }

  expect_failures = [var.user_grants]
}
