# MySQL Instance Submodule

Creates a single user with grants on a Cloud SQL **MySQL** instance.

> This is an internal sub-module. Use the root module
> (`github.com/boozt-platform/terraform-google-cloud-sql-iam`), which
> auto-detects the engine and calls this sub-module for you.

## Usage

```hcl
/**
 * Make sure the database exists before granting permissions
 */
module "mysql_permissions" {
  source = "./modules/mysql-instance/"

  user = "johndoe@example.com"
  grants = {
    "database1" = ["SELECT", "EXECUTE"],
    "database2" = ["SELECT", "EXECUTE"],
  }
  table_grants = {
    "database1.users"  = ["SELECT"],
    "database1.orders" = ["SELECT", "INSERT", "UPDATE"],
  }
  roles = {
    "database1" = ["fulldevuser"],
    "database2" = ["fulldevuser"],
  }
  type            = "CLOUD_IAM_USER"
  admin_username  = "admin"
  connection_name = "project-id:region:name"
}
```

## Validation

A `lifecycle` precondition on the `mysql_grant.instance_grants` and
`mysql_grant.instance_table_grants` resources ensures that `CLOUD_IAM_USER`
type users cannot use the wildcard `"*"` as a database name. This acts as a
defense-in-depth check alongside the root module's variable validation.

## Behavior

- **Non-superusers**: grants, table grants, and roles are created from the
  provided `grants`, `table_grants` and `roles` maps. If no grants are
  specified, no grant resources are created.
- **Table-level grants**: the `table_grants` map uses `"database.table"` keys
  to grant privileges on specific tables within a database.
- **Superusers** (when `user` matches `admin_username`): the user receives the
  `cloudsqlsuperuser` role and full privileges on all databases (`"*"`).

## Terraform docs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.53, < 8.0 |
| <a name="requirement_mysql"></a> [mysql](#requirement\_mysql) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.53, < 8.0 |
| <a name="provider_mysql"></a> [mysql](#provider\_mysql) | ~> 3.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | user name for the admin account | `string` | `null` | no |
| <a name="input_connection_name"></a> [connection\_name](#input\_connection\_name) | Single Cloud SQL instance connection name | `string` | `null` | no |
| <a name="input_grants"></a> [grants](#input\_grants) | List of grants to assign to the user for a specific database | `map(list(string))` | `{}` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | List of roles to assign to the user for a specific database | `map(list(string))` | `{}` | no |
| <a name="input_table_grants"></a> [table\_grants](#input\_table\_grants) | List of grants to assign to the user for a specific database table. Keys must be in the format 'database.table'. | `map(list(string))` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | n/a | `string` | `"CLOUD_IAM_USER"` | no |
| <a name="input_user"></a> [user](#input\_user) | Single user to create in the instance | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sql_user"></a> [sql\_user](#output\_sql\_user) | The google\_sql\_user resource created for this user. |
| <a name="output_user_name"></a> [user\_name](#output\_user\_name) | The in-database MySQL user name (the local part of the email). |
<!-- END_TF_DOCS -->
