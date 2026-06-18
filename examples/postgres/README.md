# PostgreSQL example

Manage IAM users and grants on a Cloud SQL **PostgreSQL** instance.

## Usage

```bash
terraform init
terraform apply \
  -var 'connection_name=my-project:europe-west1:my-postgres-instance' \
  -var 'admin_username=my-admin@my-project.iam' \
  -var 'admin_password=...'
```

PostgreSQL specifics handled by the module:

- IAM **service-account** role names drop the `.gserviceaccount.com` suffix.
- `grants` apply to all tables of the schema; `table_grants` accept
  `database.table` or `database.schema.table`; `schema_grants` grant
  schema-level privileges (e.g. `CREATE`, `USAGE`).
- Supply PostgreSQL-valid privilege names (not MySQL-only ones such as
  `SHOW DATABASES` or `PROCESS`).
