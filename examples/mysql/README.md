# MySQL example

Manage IAM users and grants on a Cloud SQL **MySQL** instance.

## Usage

```bash
terraform init
terraform apply \
  -var 'connection_name=my-project:europe-west1:my-mysql-instance' \
  -var 'admin_username=my-admin' \
  -var 'admin_password=...'
```

> The admin identity must be able to connect to the instance and manage grants.
> When `enable_iam = true`, `admin_password` must be a short-lived OAuth2 access
> token of the connecting identity (see the root module README for details).
