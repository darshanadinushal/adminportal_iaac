# CI, CD & IAC on Azure AKS Kubernetes Clusters - Docker, Azure DevOps & Terraform

# Create Azure K8S Cluster using Terraform

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

6. Before we are using terraform pipeline we need couple of terraform plugins 
Install it
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
9. Add $(client_id) ,$(client_secret) ssh_public_key 
$(client_id) ,$(client_secret) we can add using variables

10. Add ssh_public_key as a scure file
    Go to Library --> Secure files  --> Add the ssh key file we are create step (4)
    
11. Run the pipeline and give the permission ,by click the permit accessfile 

# Terraform Apply command execute 
12. Pipeline ymal we need to add the commad for APPLY

Go to the pipeline Copy the `init` task paste it ,
Remove the unnecessary things.
```
- task: TerraformCLI@0
  inputs:
    command: 'apply'
    workingDirectory: '$(System.DefaultWorkingDirectory)/kubernetes'
    environmentServiceName: 'adminportal-rg-service-connection'
    commandOptions: '-var client_id=$(client_id) -var client_secret=$(client_secret) -var ssh_public_key=$(publickey.secureFilePath)'
```    

13. Run the pipeline  After execute the terraform file.
      It will create Resource group Kubernetes_dev
      After execute the first step ,It will create azure kubernetes cluster  name 'terraform-k8s' inside kubernetes_dev
      
# Login Kubernete Cluster using local machine 
   1. Install the Install AZ client to local machine
   2. az login 
   3. Go To Kubernete cluster that previously created.
   4. Go to the dashboard.Run the (3) , (4) the steps.
   5. Then can use the Kubernete command. Ex- kubectl get all 
   
# Deploy  Application to Kubernete cluster. 

1. Go To Project setting --> Service connection --> new service connection

2. Create new pipeline for our application deployment     
    Go To pipeline --> GitHub --> Select Repo --> Starter pipeline
    Following step we need to do in docker
      1. Stage 1 
        ○ Build Docker Image 
        Publish the k8s Files (Deployement.yaml file)
      2. Stage 2
		○ Download the k8s Files
     Deploy to k8s Cluster with Docker Image
     
 3. Build Docker Image
```
stages: 
- stage: Buid 
  displayName: Build Image
  jobs:
  - job: Build
    displayName:  Build-job
    pool:
      vmImage: 'ubuntu-latest'
    steps: 
    - task: Docker@2
      displayName: Build an image
      inputs:
        containerRegistry: 'dockerhub-connection'
        repository: 'darshanadinushal/adminportalclientapp'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: '$(tag)'
```
4. Publish the k8s Files (Deployement.yaml file)
     Artifact name we will give any name.
```
#Publish the k8s Files (Deployement.yaml file)
    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'manifests'
        publishLocation: 'Container'
```
5. Deploy the Image to Kubernetes cluster && Copy to the Build.ArtifactStagingDirectory

```
trigger:
- develop

resources:
- repo: self

variables:
  tag: '$(Build.BuildId)'

stages: 
- stage: Buid 
  displayName: Build Image
  jobs:
  - job: Build
    displayName:  Build-job
    pool:
      vmImage: 'ubuntu-latest'
    steps: 
    - task: Docker@2
      displayName: Build an image
      inputs:
        containerRegistry: 'dockerhub-connection'
        repository: 'darshanadinushal/adminportalclientapp'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: '$(tag)'

    - task: CopyFiles@2
      inputs:
        SourceFolder: '$(System.DefaultWorkingDirectory)'
        Contents: '**/*.yaml'
        TargetFolder: '$(Build.ArtifactStagingDirectory)'

    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'manifests'
        publishLocation: 'Container'

- stage: Deploy 
  displayName: Deploy Image
  jobs:
  - job: Deploy
    displayName: Deploy
    pool:
      vmImage: 'ubuntu-latest'
    steps: 
    - script: |
        echo 1 > "$(System.ArtifactsDirectory)"
        echo 2 > "$(System.ArtifactsDirectory)/manifests"
    - task: DownloadPipelineArtifact@2
      inputs:
        buildType: 'current'
        artifactName: 'manifests'
        itemPattern: '**/*.yaml'
        targetPath: '$(System.ArtifactsDirectory)'

    - task: KubernetesManifest@0
      inputs:
        action: 'deploy'
        kubernetesServiceConnection: 'adminportal-kubernetes-connection'
        namespace: 'default'
        manifests: '$(System.ArtifactsDirectory)/configuration/kubernetes/deployment.yaml'
        containers: 'darshanadinushal/adminportalclientapp:$(tag)'
```    
      



    





