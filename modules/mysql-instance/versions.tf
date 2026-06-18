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
  }
}
