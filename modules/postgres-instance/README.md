# PostgreSQL Instance Submodule

Creates a single user with grants on a Cloud SQL **PostgreSQL** instance.

This is the PostgreSQL counterpart of the
[`mysql-instance`](../mysql-instance/) (MySQL) sub-module. The root module
selects between them automatically based on the detected `database_version` of
the Cloud SQL instance, so callers never invoke this module directly and the
public usage stays engine-agnostic.

## Usage

```hcl
/**
 * Make sure the database exists before granting permissions
 */
module "postgres_permissions" {
  source = "./modules/postgres-instance/"

  user = "johndoe@example.com"
  grants = {
    "database1" = ["SELECT", "INSERT"],
  }
  table_grants = {
    "database1.users"          = ["SELECT"],
    "database1.sales.invoices" = ["SELECT", "INSERT", "UPDATE"], // database.schema.table
  }
  roles = {
    "*" = ["fulldevuser"],
  }
  type            = "CLOUD_IAM_USER"
  admin_username  = "postgres"
  connection_name = "project-id:region:name"
}
```

## Behavior & PostgreSQL specifics

- **IAM role names** follow the Cloud SQL PostgreSQL rules
  (see [docs](https://cloud.google.com/sql/docs/postgres/iam-logins)):
  - `CLOUD_IAM_USER` / `CLOUD_IAM_GROUP`: the **full email address** is the role.
  - `CLOUD_IAM_SERVICE_ACCOUNT`: the email **without** the `.gserviceaccount.com`
    suffix is the role.
- **Database grants** (`grants`) are applied as table privileges on all tables
  of the schema (`default_schema`, defaults to `public`) of the target
  database, mirroring the MySQL "all tables in this database" semantics.
- **Table grants** (`table_grants`) accept keys in either `"database.table"`
  (assumes `default_schema`) or `"database.schema.table"` (explicit schema)
  format.
- **Roles** (`roles`) are applied as PostgreSQL role memberships
  (`postgresql_grant_role`). Role membership is cluster-wide in PostgreSQL, so
  the database key is preserved only to keep the input shape identical to the
  MySQL sub-module; duplicate roles across databases are de-duplicated.
- **Superusers** (when `user` matches `admin_username`) receive the
  `cloudsqlsuperuser` role.
- **Privileges pass through verbatim** to the provider. Callers are responsible
  for supplying PostgreSQL-valid privilege names (e.g. `SELECT`, `INSERT`,
  `USAGE`, `EXECUTE`) for PostgreSQL instances.

## Validation

`lifecycle` preconditions on the grant resources ensure that `CLOUD_IAM_USER`
type users cannot use the wildcard `"*"` as a database name, acting as
defense-in-depth alongside the root module's variable validation.

## Cross-database grants

A single `postgresql` provider connection (to the default `postgres` database)
is sufficient: the `postgresql_grant` resource takes a `database` argument and
the provider transparently re-connects to the target database per grant.

## Terraform docs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.53, < 8.0 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | ~> 1.22 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.53, < 8.0 |
| <a name="provider_postgresql"></a> [postgresql](#provider\_postgresql) | ~> 1.22 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | user name for the admin account | `string` | `null` | no |
| <a name="input_connection_name"></a> [connection\_name](#input\_connection\_name) | Single Cloud SQL instance connection name | `string` | `null` | no |
| <a name="input_default_schema"></a> [default\_schema](#input\_default\_schema) | Schema assumed for two-part 'database.table' table\_grants keys | `string` | `"public"` | no |
| <a name="input_grants"></a> [grants](#input\_grants) | List of grants to assign to the user for a specific database | `map(list(string))` | `{}` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | List of roles to assign to the user for a specific database | `map(list(string))` | `{}` | no |
| <a name="input_schema_grants"></a> [schema\_grants](#input\_schema\_grants) | Schema-level privileges (e.g. CREATE, USAGE) to assign to the user. Keys must be in the format 'database' (assumes the default schema) or 'database.schema'. | `map(list(string))` | `{}` | no |
| <a name="input_table_grants"></a> [table\_grants](#input\_table\_grants) | List of grants to assign to the user for a specific database table. Keys must be in the format 'database.table' or 'database.schema.table'. | `map(list(string))` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | n/a | `string` | `"CLOUD_IAM_USER"` | no |
| <a name="input_user"></a> [user](#input\_user) | Single user to create in the instance | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sql_user"></a> [sql\_user](#output\_sql\_user) | The google\_sql\_user resource created for this user. |
| <a name="output_user_name"></a> [user\_name](#output\_user\_name) | The in-database PostgreSQL role name. For CLOUD\_IAM\_SERVICE\_ACCOUNT this is<br/>the email without the ".gserviceaccount.com" suffix; otherwise the full<br/>email. |
<!-- END_TF_DOCS -->
