# Terraform AWS
Terraform scripts for AWS EKS

## Requirements
- You must have aws cli configured
- The required terraform version is 0.11.13 or higher

## Instructions
- Change tfvars values with your environment preferences
- Execute `terraform apply` and type yes to deploy the infrastructure
- Install latest kubectl version following these instructions - [https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html]
- To retrieve kubectl config from EKS, run `aws eks update-kubeconfig --name <cluster_name>`
- You'll receive an output with config_map configuration. Save it into a file called config_map.yaml and execute `kubectl apply -f config_map.yaml`

