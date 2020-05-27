# CI, CD & IAC on Azure AKS Kubernetes Clusters - Docker, Azure DevOps & Terraform

1. Install AZ client to local machine
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

2.  Run the az login command in cmd.

3. Create Service Account To Create Azure K8S Cluster using Terraform
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<<azure_subscription_id>>"
Here we give role base access control  role  of "Contributor" ,that role can access given subscription all the things. 
```
{
  "appId": "xxxxxxx-sampleId",
  "displayName": "azure-cli-2020-05-21-15-48-26",
  "name": "http://azure-cli-2020-05-21-15-48-26",
  "password": "s^4h4xa7u2RO$7>]sample",
  "tenant": "xxxxxxxx0-53ca-47b2-sample"
}
```

4. Create Public Key for SSH Access
ssh-keygen -m PEM -t rsa -b 4096 

5. We create a connection to Azure.
Go To Project setting --> Service connection --> New Service connection --> Azure Resource Manager

6. Before we are using terraform pipeline we need couple of terraform plugins ,Install it
Terraform 1 (https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)
Terraform 2 (https://marketplace.visualstudio.com/items?itemName=charleszipp.azure-pipelines-tasks-terraform)


7. Create New pipeline 
Go to Pipeline --> GitHub --> Select Repo --> Select Starter pipeline

8. Add Terraform CLI task to YAML.

```
- task: TerraformCLI@0
  inputs:
    command: 'init'
    workingDirectory: '$(System.DefaultWorkingDirectory)/kubernetes'
    #commandOptions: '-var client_id=$(client_id) -var client_secret=$(client_secret) -var ssh_public_key=$(publickey.secureFilePath)'
    backendType: 'azurerm'
    backendServiceArm: 'adminportal-rg-service-connection'
    ensureBackend: true
    backendAzureRmResourceGroupName: 'adminportal-rg'
    backendAzureRmResourceGroupLocation: 'westeurope'
    backendAzureRmStorageAccountName: 'adminportalstorageac'
    backendAzureRmContainerName: 'adminportalcontainer'
    backendAzureRmKey: 'adminportal-dev.tfstate'
```


