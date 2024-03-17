---

# Azure Resources Deployment using Terraform

This Terraform script deploys the following Azure resources:

1. **App Service Plan**
2. **App Service**: Integrated with VNet, with System Managed Identity enabled
3. **Application Insights**: Linked to the App Service
4. **Azure Container Registry (ACR)**: App Service Identity has access
5. **Key Vault**: App Service Identity has permissions, integrated with VNet
6. **Virtual Network (VNet)**
7. **MS SQL Server DB**: Configured with Private Endpoint
8. **Storage Account**: Private Endpoint configured with VNet, Fileshare mounted to App Service
9. **Storage Account for Terraform state**

## Prerequisites

Before running the Terraform script, make sure you have:

- An Azure subscription
- Azure CLI installed
- Terraform installed

## How to Use

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/your-repo.git
   ```

2. Navigate to the repository:

   ```bash
   cd your-repo
   ```

3. Initialize Terraform:

   ```bash
   terraform init
   ```

4. Modify the `variables.tf` file to set your desired values.

5. Review and apply the Terraform plan:

   ```bash
   terraform plan
   terraform apply
   ```

## Outputs

- `app_service_url`: URL of the deployed App Service.

## Cleanup

To clean up the resources created by this script, run:

```bash
terraform destroy
```

**Note**: This will destroy all resources created by this Terraform script.
