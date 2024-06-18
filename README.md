Azure Terraform Datasunrsie 

What this script does?
============================================================================
This script will deploy for you:
    -> A multi-zone PostgreSQL instance for Dictionary
    -> A multi-zone PostgreSQL instance for Audit
    -> A server load balancer
    -> An autoscaling group
    -> A Computer Cloud instance with DataSunrise running


Limitations
============================================================================
1. Existing infrastructure must be located on a region with multiple availability zones.
2. Chosen region must support DB and SLB.
3. Define these three environment variables:
      ARM_CLIENT_ID="SET-CLIENT-KEY-HERE"
      ARM_CLIENT_SECRET="SET-CLIENT-SECRET-HERE"
      ARM_SUBSCRIPTION_ID="SET-SUBSCRIPTION-ID-HERE"
      ARM_TENANT_ID="SET-TENANT-ID-HERE"
4. Selected availability zones must be part of a "multi zone".


Pre-deployment instructions
============================================================================
1. You need to have an already created an OSS bucket.
2. Upload to this bucket DataSunrise installer (named as DataSunrise_Suite_installer.run).
3. Edit the file terrafrom.tfvars and set all the values that better fits your
   requirements.(Open this file for editing by some editor, for example: Notepad++)
4. Download terraform cli for your OS and move it to the folder with scripts (https://www.terraform.io/downloads)
5. Download Azure CLI for your OS

---
Authenticating using a Service Principal with a Client Secret:
https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html
---

Deployment instructions
============================================================================
1. Execute:
      terraform init
   to initialize the working directory.

2. Execute:
      terraform plan
   to create an execution plan.

3. Execute:
      terraform apply
   to start the deployment.
