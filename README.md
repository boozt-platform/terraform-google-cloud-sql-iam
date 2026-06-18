<!-- markdownlint-disable MD013 MD041 -->
<a href="https://github.com/boozt-platform/terraform-google-cloud-sql-iam">
  <img src="https://raw.githubusercontent.com/boozt-platform/branding/main/assets/img/platform-logo.png" alt="Boozt Platform" />
</a>
<!-- markdownlint-enable MD013 -->

[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/boozt-platform/terraform-google-cloud-sql-iam.svg?label=latest&sort=semver)](https://github.com/boozt-platform/terraform-google-cloud-sql-iam/releases)
[![license](https://img.shields.io/badge/license-mit-brightgreen.svg)](./LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6.0-blue.svg)](https://www.terraform.io/)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue.svg)](https://opentofu.org/)

# Terraform Google Cloud SQL IAM

Terraform module to manage database users and their grants on Google Cloud SQL
instances using **IAM database authentication**. It supports both **MySQL** and
**PostgreSQL** and selects the right engine automatically, exposing a single,
engine-agnostic interface.

## Table of Contents

- [Features](#features)
- [Engine auto-detection](#engine-auto-detection)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [PostgreSQL specifics](#postgresql-specifics)
- [Validation rules](#validation-rules)
- [Known limitations](#known-limitations)
- [Examples](#examples)
- [Testing](#testing)
- [Terraform docs](#terraform-docs)
- [About Boozt](#about-boozt)
- [Reporting Issues](#reporting-issues)
- [Contributing](#contributing)
- [License](#license)

## Features

- **One interface, two engines** - the same `user_grants` / `configuration`
  inputs work for MySQL and PostgreSQL.
- **Engine auto-detection** - reads the instance `database_version` and routes
  to the correct sub-module; callers never specify the engine.
- **IAM database authentication** - manages `CLOUD_IAM_USER`,
  `CLOUD_IAM_SERVICE_ACCOUNT` and `CLOUD_IAM_GROUP` users.
- **Fine-grained grants** - database-level, table-level
  (`database.table` / `database.schema.table`) and, for PostgreSQL,
  schema-level (`CREATE` / `USAGE`) privileges, plus role memberships.
- **Least privilege guardrails** - input validation forbids wildcard databases
  for regular IAM users.

## Engine auto-detection

The module reads the instance's `database_version` via a
`google_sql_database_instance` data source and routes to the MySQL or
PostgreSQL sub-module accordingly. Both the `mysql` and `postgresql` providers
are declared internally, but each engine's resources are gated on the detected
engine and both providers connect lazily, so the provider for the unused engine
never opens a connection.

## Prerequisites

- The target Cloud SQL instance must have **IAM database authentication
  enabled** (`cloudsql.iam_authentication = on`).
- The identity running Terraform/OpenTofu needs:
  - `cloudsql.instances.get` on the instance (used by the engine-detection
    data source) — e.g. `roles/cloudsql.viewer`.
  - The ability to authenticate to the database as the configured
    `admin_username` with privileges to manage the requested grants.
- The relevant database(s) must already exist before granting permissions.

## Usage

This module is published to both the [Terraform Registry][tf-registry] and the
[OpenTofu Registry][otf-registry]:

```hcl
module "cloud_sql_iam" {
  source  = "boozt-platform/cloud-sql-iam/google"
  version = "~> 1.1"

  configuration = {
    connection_name = "my-project:europe-west1:my-instance"
    admin_username  = "my-admin"
    admin_password  = "..." # or a short-lived OAuth2 token when enable_iam = true
    enable_iam      = false
  }

  user_grants = [
    {
      email     = "my-service-account@my-project.iam.gserviceaccount.com"
      user_type = "CLOUD_IAM_SERVICE_ACCOUNT"
      grants    = { "*" = ["SELECT", "INSERT", "UPDATE", "DELETE"] }
    },
    {
      # CLOUD_IAM_USER (default) must specify explicit database names.
      email = "user1@example.com"
      grants = {
        "my_application_db" = ["SELECT", "INSERT", "UPDATE", "DELETE"]
        "reporting_db"      = ["SELECT"]
      }
    }
  ]
}
```

Alternatively, you can source the module directly from GitHub by tag, e.g.
`source = "github.com/boozt-platform/terraform-google-cloud-sql-iam?ref=v1.1.0"`.

## PostgreSQL specifics

When the target instance is PostgreSQL, the same inputs apply, with these
engine differences (all handled by the module):

| Topic | Behavior on PostgreSQL |
|-------|------------------------|
| IAM role name | `CLOUD_IAM_USER` / `CLOUD_IAM_GROUP` use the **full email**; `CLOUD_IAM_SERVICE_ACCOUNT` uses the email **without** the `.gserviceaccount.com` suffix (per [Cloud SQL docs](https://cloud.google.com/sql/docs/postgres/iam-logins)). |
| `grants` | Applied as table privileges on **all tables** of the schema (`public` by default) of each named database. |
| `table_grants` | Keys may be `database.table` (assumes `public` schema) **or** `database.schema.table`. |
| `schema_grants` | Schema-level privileges (e.g. `CREATE`, `USAGE`). Keys may be `database` (default schema) or `database.schema`. |
| `roles` | Applied as cluster-wide role memberships. |
| Privileges | Passed through verbatim — supply **PostgreSQL-valid** privileges. MySQL-only privileges such as `SHOW DATABASES` or `PROCESS` are not valid. |

## Validation rules

The `user_grants` variable enforces the following:

| Rule | Description |
|------|-------------|
| Unique emails | Each `email` must be unique. |
| No wildcard database for `CLOUD_IAM_USER` | Regular IAM users must name explicit databases in `grants`, `table_grants` and `schema_grants`; `"*"` is rejected. Service accounts and groups may use `"*"`. |
| `table_grants` key format | `database.table` or `database.schema.table`, no empty parts. |
| `schema_grants` key format | `database` or `database.schema`, no empty parts (PostgreSQL only). |

## Known limitations

- **Provider configuration lives inside the module.** This is required to fan
  out to a per-user sub-module with `for_each`. As a result, callers cannot
  currently supply their own `mysql` / `postgresql` provider configuration. A
  future major version may move provider configuration to the caller; expect a
  breaking change when that happens.
- **PostgreSQL grants require ownership/superuser.** Cloud SQL's
  `cloudsqlsuperuser` is not a true superuser and cannot `GRANT` on objects it
  does not own. Granting on tables owned by another role must be performed by
  the owner.

## Examples

- [examples/mysql](./examples/mysql) - Cloud SQL MySQL instance
- [examples/postgres](./examples/postgres) - Cloud SQL PostgreSQL instance

## Testing

This module uses Terraform's native testing framework with mock providers (no
GCP credentials required):

```bash
task test
# or
terraform test
```

## Terraform docs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.53, < 8.0 |
| <a name="requirement_mysql"></a> [mysql](#requirement\_mysql) | ~> 3.0 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | ~> 1.22 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.53, < 8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mysql_permissions"></a> [mysql\_permissions](#module\_mysql\_permissions) | ./modules/mysql-instance/ | n/a |
| <a name="module_postgres_permissions"></a> [postgres\_permissions](#module\_postgres\_permissions) | ./modules/postgres-instance/ | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_user_grants"></a> [user\_grants](#input\_user\_grants) | Map of grants for each users | <pre>list(object({<br/>    email         = string<br/>    user_type     = optional(string, "CLOUD_IAM_USER")<br/>    grants        = optional(map(list(string)), {})<br/>    table_grants  = optional(map(list(string)), {})<br/>    schema_grants = optional(map(list(string)), {})<br/>    roles         = optional(map(list(string)), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_auth_type"></a> [auth\_type](#input\_auth\_type) | Sets the authentication plugin, it can be one of the following: `native` or `cleartext` | `string` | `"native"` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | Username and password for Cloud SQL instance admin user | <pre>object({<br/>    connection_name = string<br/>    admin_username  = string<br/>    admin_password  = string<br/>    enable_iam      = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "admin_password": null,<br/>  "admin_username": null,<br/>  "connection_name": null,<br/>  "enable_iam": false<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_version"></a> [database\_version](#output\_database\_version) | The raw database\_version reported by the Cloud SQL instance (e.g. "POSTGRES\_15", "MYSQL\_8\_0"). |
| <a name="output_engine"></a> [engine](#output\_engine) | The database engine auto-detected from the Cloud SQL instance's<br/>database\_version. Either "mysql" or "postgres". |
| <a name="output_managed_users"></a> [managed\_users](#output\_managed\_users) | The list of user emails managed by this module on the target instance. |
| <a name="output_mysql_user_names"></a> [mysql\_user\_names](#output\_mysql\_user\_names) | Map of email to the in-database MySQL user name for each managed user.<br/>Empty when the target instance is PostgreSQL. |
| <a name="output_postgres_user_names"></a> [postgres\_user\_names](#output\_postgres\_user\_names) | Map of email to the in-database PostgreSQL role name for each managed user.<br/>For service accounts this is the email without the ".gserviceaccount.com"<br/>suffix. Empty when the target instance is MySQL. |
<!-- END_TF_DOCS -->

## About Boozt

Boozt is a leading and fast-growing Nordic technology company selling fashion
and lifestyle online mainly through its multi-brand webstore
[Boozt.com](https://www.boozt.com/) and [Booztlet.com](https://www.booztlet.com/).

The company is focused on using cutting-edge, in-house developed technology to
curate the best possible customer experience.

See our [Medium](https://medium.com/boozt-tech) blog page for technology-focused
articles. Would you like to make your mark by working with us at Boozt? Take a
look at our [latest hiring opportunities](https://careers.booztgroup.com/).

## Reporting Issues

Please provide a clear and concise description of the problem or the feature
you're missing along with any relevant context. Check existing issues before
reporting to avoid duplicates.

## Contributing

Contributions are highly valued and very welcome! For the process of reviewing
changes we use [Pull Requests](https://github.com/boozt-platform/terraform-google-cloud-sql-iam/pulls).
For detailed information please follow the
[Contribution Guidelines](./docs/CONTRIBUTING.md).

## License

This project is licensed under the MIT License. Please see [LICENSE](./LICENSE)
for full details.

[tf-registry]: https://registry.terraform.io/modules/boozt-platform/cloud-sql-iam/google/latest
[otf-registry]: https://search.opentofu.org/module/boozt-platform/cloud-sql-iam/google/latest
