// Execute this main file to depoy Azure AI studio resources in the basic security configuraiton

targetScope = 'subscription'

// Parameters
@minLength(2)
@maxLength(12)
@description('Name for the AI resource and used to derive name of dependent resources.')
param aiHubName string = 'agent-hub'

@description('Friendly name for your Azure AI resource')
param aiHubFriendlyName string = 'Agent sample hub'

@description('Description of your Azure AI resource dispayed in AI studio')
param aiHubDescription string = 'A hub resource required for the agent setup.'

@description('Name for the project')
param aiProjectName string = 'agent-project'

@description('Friendly name for your Azure AI resource')
param aiProjectFriendlyName string = 'Agents project resource'

@description('Description of your Azure AI resource dispayed in AI studio')
param aiProjectDescription string = 'A standard project resource required for the agent setup.'

@minLength(1)
@description('Primary location for all resources')
@allowed([
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'swedencentral'
  'westus'
  'westus3'
])
param location string

@description('Set of tags to apply to all resources.')
param tags object = {}

@description('Model name for deployment')
param modelName string = 'gpt-4o'

@description('Model format for deployment')
param modelFormat string = 'OpenAI'

@description('Model version for deployment')
param modelVersion string = '2024-11-20'

@description('Model deployment SKU name')
param modelSkuName string = 'GlobalStandard'

@description('Model deployment capacity')
param modelCapacity int = 140

@description('Model deployment location. If you want to deploy an Azure AI resource/model in different location than the rest of the resources created.')
param modelLocation string = 'westus'

@description('Whether the deployment is running on GitHub Actions')
param runningOnGh string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Flag to decide where to create OpenAI role for current user')
param createRoleForUser bool = true

param envName string = ''

param bingConnectionName string = 'groundingwithbingsearch'

@secure()
param chainlitAuthSecret string
@secure()
param agentPassword string = substring(uniqueString(subscription().id, aiHubName, newGuid()), 0, 12)

param acaExists bool = false

// Variables
var name = toLower('${aiHubName}')
var projectName = toLower('${aiProjectName}')

@description('Name of the storage account')
param storageName string = 'agentservicestorage'

@description('Name of the Azure AI Services account')
param aiServicesName string = 'agent-ai-services'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${envName}'
  location: location
  tags: tags
}

// Create a short, unique suffix, that will be unique to each resource group
// var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)
param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')
var uniqueSuffix = substring(uniqueString('${resourceGroup.id}-${deploymentTimestamp}'), 0, 4)

var resourceToken = 'a${toLower(uniqueString(subscription().id, aiHubName, location))}'

// Dependent resources for the Azure Machine Learning workspace
module aiDependencies 'modules-basic-keys/basic-dependent-resources-keys.bicep' = {
  name: 'dependencies-${name}-${uniqueSuffix}-deployment'
  scope: resourceGroup
  params: {
    aiServicesName: '${aiServicesName}-${uniqueSuffix}'
    storageName: '${storageName}${uniqueSuffix}'
    location: location
    tags: tags

     // Model deployment parameters
     modelName: modelName
     modelFormat: modelFormat
     modelVersion: modelVersion
     modelSkuName: modelSkuName
     modelCapacity: modelCapacity
     modelLocation: modelLocation
  }
}

module aiHub 'modules-basic-keys/basic-ai-hub-keys.bicep' = {
  name: 'ai-${name}-${uniqueSuffix}-deployment'
  scope: resourceGroup
  params: {
    // workspace organization
    aiHubName: 'ai-${name}-${uniqueSuffix}'
    aiHubFriendlyName: aiHubFriendlyName
    aiHubDescription: aiHubDescription
    location: location
    tags: tags

    // dependent resources
    modelLocation: modelLocation
    storageAccountId: aiDependencies.outputs.storageId
    aiServicesId: aiDependencies.outputs.aiservicesID
    aiServicesTarget: aiDependencies.outputs.aiservicesTarget
  }
}

module aiProject 'modules-basic-keys/basic-ai-project-keys.bicep' = {
  name: 'ai-${projectName}-${uniqueSuffix}-deployment'
  scope: resourceGroup
  params: {
    // workspace organization
    aiProjectName: 'ai-${projectName}-${uniqueSuffix}'
    aiProjectFriendlyName: aiProjectFriendlyName
    aiProjectDescription: aiProjectDescription
    location: location
    tags: tags

    // dependent resources
    aiHubId: aiHub.outputs.aiHubID
  }
}

module bingSearchGrounding 'bing-grounding.bicep' = {
  name: 'bing-search-grounding'
  scope: resourceGroup
  params: {
    name: bingConnectionName
    location: location
    bingAccountName: 'ai-${aiServicesName}-bing-grounding'
  }
}

module logAnalyticsWorkspace 'core/monitor/loganalytics.bicep' = {
  name: 'loganalytics'
  scope: resourceGroup
  params: {
    name: '${resourceToken}-loganalytics'
    location: location
    tags: tags
  }
}

// Container apps host (including container registry)
module containerApps 'core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: resourceGroup
  params: {
    name: 'app'
    location: location
    tags: tags
    containerAppsEnvironmentName: '${resourceToken}-containerapps-env'
    containerRegistryName: '${replace(resourceToken, '-', '')}registry'
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
}

// Container app frontend
module aca 'aca.bicep' = {
  name: 'aca'
  scope: resourceGroup
  params: {
    name: replace('${take(resourceToken,19)}-ca', '--', '-')
    location: location
    tags: tags
    identityName: '${resourceToken}-id-aca'
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    exists: acaExists
    chainlitAuthSecret: chainlitAuthSecret
    openAiDeploymentName: modelName
    userPassword: agentPassword
    projectConnectionString: aiProject.outputs.aiProjectConnectionString
  }
}

module openAiRoleUser 'core/security/role.bicep' = if (createRoleForUser && empty(runningOnGh)) {
  scope: resourceGroup
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'f6c7c914-8db3-469d-8ca1-694a8f32e121'
    principalType: 'User'
  }
}

module openAiRoleBackend 'core/security/role.bicep' = {
  name: 'openai-role-backend'
  scope: resourceGroup
  params: {
    principalId: aca.outputs.SERVICE_ACA_IDENTITY_PRINCIPAL_ID
    roleDefinitionId: 'f6c7c914-8db3-469d-8ca1-694a8f32e121'
    principalType: 'ServicePrincipal'
  }
}

//output subscriptionId string = subscription().subscriptionId
//output resourceGroupName string = resourceGroup.name
//output aiProjectName string = 'ai-${projectName}-${uniqueSuffix}'
//output bingGroundingName string = 'bing-grounding-${uniqueSuffix}'
output PROJECT_CONNECTION_STRING string = aiProject.outputs.aiProjectConnectionString
output BING_CONNECTION_NAME string = bingConnectionName
output MODEL_DEPLOYMENT_NAME string = modelName
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
#disable-next-line outputs-should-not-contain-secrets
output CHAINLIT_AUTH_SECRET string = chainlitAuthSecret
#disable-next-line outputs-should-not-contain-secrets
output AGENT_PASSWORD string = agentPassword
