| Stage                       | Job                                          | Build Status                                                                                                                                                                                             |
|-----------------------------|----------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Infrastructure rebuild      | Code validation and infrastructure deploy    | [![Build Status](https://dev.azure.com/supercomf128/BeStrong/_apis/build/status/Maksym-Perehinets.DevOps-growth-lab-1?branchName=master&stageName=Infrastructure%20rebuild&jobName=Code%20validation%20and%20infrastructure%20deploy%20(terraform%20validate%2Fapply))](https://dev.azure.com/supercomf128/BeStrong/_build/latest?definitionId=7&branchName=master) |
| Test build                  | Code validation and dry run                 | [![Build Status](https://dev.azure.com/supercomf128/BeStrong/_apis/build/status/Maksym-Perehinets.DevOps-growth-lab-1?branchName=master&stageName=Test%20build&jobName=Code%20validation%20and%20dry%20run%20(terraform%20validate%2Fplan))](https://dev.azure.com/supercomf128/BeStrong/_build/latest?definitionId=7&branchName=master) |

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



This repository follows the Trunk Based Development flow for Continuous Integration and Continuous Deployment (CI/CD) processes. Trunk Based Development emphasizes working directly on the main branch, promoting collaboration and fast feedback loops.



## Azure DevOps Pipeline

I have implemented a CI/CD pipeline using YAML syntax and committed it to this GitHub repository. The pipeline is triggered on commits to the main branch and includes the following steps:

1. Terraform init
2. Terraform validate
3. Terraform apply

For Pull Requests (PR), the CI pipeline includes additional steps:

1. Terraform init
2. Terraform validate
3. Terraform plan

## Pipeline Setup in Azure DevOps

1. Create a pipeline in Azure DevOps using the YAML file from this repository.
2. The pipeline deploys infrastructure into Azure Cloud using Terraform as part of the CI/CD process.
3. I use GitHub service connection to access the repository and Azure service principal connection to grant the Azure agent necessary permissions for actions on Azure.

Feel free to explore the code and pipeline configurations in this repository. For any questions or issues, please contact me.
