# MySQL example

Manage IAM users and grants on a Cloud SQL **MySQL** instance.

## Module source

This example sources the module locally (`source = "../../"`) so it always
validates against the code in this repository. When consuming the published
module, reference it from the Terraform or OpenTofu registry instead:

```hcl
module "cloud_sql_iam" {
  source  = "boozt-platform/cloud-sql-iam/google"
  version = "~> 1.1"

  # configuration = { ... }
  # user_grants   = [ ... ]
}
```

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
