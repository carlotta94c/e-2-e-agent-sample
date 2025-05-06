param name string
param location string = resourceGroup().location
param tags object = {}
param bingConnectionName string = 'groundingwithbingsearch'

param identityName string
param containerAppsEnvironmentName string
param containerRegistryName string
param serviceName string = 'aca'
param exists bool
param openAiDeploymentName string
@secure()
param chainlitAuthSecret string
@secure()
param projectConnectionString string
@secure()
param userPassword string

resource acaIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}


module app 'core/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityName: acaIdentity.name
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    containerCpuCoreCount: '0.25'
    containerMemory: '0.5Gi'
    containerMaxReplicas: 1
    secrets:[
      {
        name: 'azure-openai-deployment'
        value: openAiDeploymentName
      }
      {
        name: 'project-connection-string'
        value: projectConnectionString
      }
      {
        name: 'chainlit-auth-secret'
        value: chainlitAuthSecret
      }
      {
        name: 'user-password'
        value: userPassword
      }
      {
        name: 'bing-connection-name'
        value: bingConnectionName
      }
    ]
    env: [
      {
        name: 'MODEL_DEPLOYMENT_NAME'
        secretRef: 'azure-openai-deployment'
      }
      {
        name: 'PROJECT_CONNECTION_STRING'
        secretRef: 'project-connection-string'
      }
      {
        name: 'CHAINLIT_AUTH_SECRET'
        secretRef: 'chainlit-auth-secret'
      }
      {
        name: 'AGENT_PASSWORD'
        secretRef: 'user-password'
      }
      {
        name: 'ENV'
        value: 'production'
      }
      {
        name: 'BING_CONNECTION_NAME'
        secretRef: 'bing-connection-name'
      }
    ]
    targetPort: 8080
  }
}

output SERVICE_ACA_IDENTITY_PRINCIPAL_ID string = acaIdentity.properties.principalId
output SERVICE_ACA_NAME string = app.outputs.name
output SERVICE_ACA_URI string = app.outputs.uri
output SERVICE_ACA_IMAGE_NAME string = app.outputs.imageName
