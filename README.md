# Terraform — Environments (dev and prod) with VPC + EKS

This project contains infrastructure defined using Terraform, organized into two independent environments: dev and prod.
Each environment creates its own VPC and EKS cluster.

## Project Structure
```bash
.
├── README.md
└── envs
    ├── dev
    │   ├── backend.tf
    │   ├── locals.tf
    │   ├── main.tf
    │   ├── terraform.tfvars
    │   └── variables.tf
    └── prod
        ├── backend.tf
        ├── locals.tf
        ├── main.tf
        ├── terraform.tfvars
        └── variables.tf
```

## Environments
Each folder under envs/ represents an isolated Terraform environment:

**dev/** → Development infrastructure

**prod/** → Production infrastructure

## Authentication
Generate AWS credentials and export them as variables
```bash
export AWS_ACCESS_KEY_ID="access_key"
export AWS_SECRET_ACCESS_KEY="secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

## Backend Configuration
The **backend.tf** file in each environment contains a placeholder bucket name for storing the Terraform state.

You must replace the placeholder with your actual bucket:

```bash
terraform {
  backend "s3" {
    bucket = "<YOUR_BUCKET_NAME>-terraform-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

## How to Use
Go into the environment you want to deploy (dev or prod):

1. Initialize Terraform
```bash
terraform init --upgrade
```

2. Validate configuration
```bash
terraform validate
```

3. Check code formatting
```bash
terraform fmt -check -diff
```

4. Preview execution plan
```bash
terraform plan
```

5. Apply changes
```bash
terraform apply
```
