# Build a Contoso Sales Analyst Agent with Azure AI Agent Service

## Scenario

Imagine you are a sales manager at Contoso, a multinational retail company that sells outdoor equipment. You need to analyze sales data to find trends, understand customer preferences, and make informed business decisions. To help you, Contoso has developed a conversational agent that can answer questions about your sales data.

## Solution Overview

The Contoso Sales Assistant is a conversational agent that can answer questions about sales data, generate charts, and create Excel files for further analysis.

The app is built with [Azure OpenAI GPT-4o](https://learn.microsoft.com/azure/ai-services/openai/concepts/models) , the [Azure AI Agent Service](https://learn.microsoft.com/en-us/azure/ai-services/agents/) and the [Chainlit](https://docs.chainlit.io/) Conversational AI  web framework.

The app uses a read-only SQLite Contoso Sales Database with 40,000 rows of synthetic data. When the app starts, it reads the sales database schema, product categories, product types, and reporting years, then adds this info to the Azure OpenAI Assistants API instruction context.

The Contoso Sales Assistant app is deployed to Azure using Azure Container Apps. The app is fully asynchronous, uses the FastAPI framework, and streams all responses to users in real-time.

> !NOTE
> This sample builds on the [original Contoso Sales Assistant App](https://github.com/Azure-Samples/contoso-sales-azure-openai-assistants-api), but it uses the Azure AI Agent Service vs the [Azure OpenAI Assistants API](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/assistants). Learn more about the differences between the two APIs in the [Azure AI Agent Service documentation](https://learn.microsoft.com/en-us/azure/ai-services/agents/overview#comparing-azure-agents-and-azure-openai-assistants).
> This sample is also available as a [step-by-step lab](https://aka.ms/aitour/wrk552). 

## Set Up

### Prerequisites
1. Access to an Azure subscription. If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free/) before you begin. You also need 140K quota for gpt-4o in EastUS2 (default region for the sample).
1. You need a GitHub account. If you don’t have one, create it at [GitHub](https://github.com/join).

### Get started
The preferred way to run this workshop is using GitHub Codespaces. This option provides a pre-configured environment with all the tools and resources needed to complete the workshop. 

Select **Open in GitHub Codespaces** to open the project in GitHub Codespaces.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/carlotta94c/e-2-e-agent-sample)

You need to authenticate with Azure so the agent app can access the Azure AI Agents Service and models. Follow these steps:

1. Ensure the Codespace has been created.
1. In the Codespace, open a new terminal window by selecting **Terminal** > **New Terminal** from the **VS Code menu**.
1. Run the following command to authenticate with Azure:

    ```shell
    az login --use-device-code
    ```

    !!! note
        You'll be prompted to open a browser link and log in to your Azure account. Be sure to copy the authentication code first.

        1. A browser window will open automatically, select your account type and click **Next**.
        2. Sign in with your Azure subscription **Username** and **Password**.
        3. **Paste** the authentication code.
        4. Select **OK**, then **Done**.

    !!! warning
        If you have multiple Azure tenants, then you will need to select the appropriate tenant when authenticating.

        ```shell
        az login --use-device-code --tenant <tenant_id>
        ```

1. Next, select the appropriate subscription from the command line.
1. Leave the terminal window open for the next steps.

## Deploy the Azure Resources

The following resources will be created in the `rg-contoso-agent-workshop` resource group in your Azure subscription.

- An **Azure AI Foundry hub** named **agent-wksp**
- An **Azure AI Foundry project** named **Agent Service Workshop**
- A **Serverless (pay-as-you-go) GPT-4o model deployment** named **gpt-4o (Global 2024-11-22)**. See pricing details [here](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/).
- A **Grounding with Bing Search** resource. See the [documentation](https://learn.microsoft.com/azure/ai-services/agents/how-to/tools/bing-grounding) and [pricing](https://www.microsoft.com/en-us/bing/apis/grounding-pricing) for details.

!!! warning "You will need 140K TPM quota availability for the gpt-4o Global Standard SKU, not because the agent uses lots of tokens, but due to the frequency of calls made by the agent to the model. Review your quota availability in the [AI Foundry Management Center](https://ai.azure.com/managementCenter/quota)."

The script `deploy.sh` deploys to the `eastus2` region by default; edit the file to change the region or resource names. To run the script, open the VS Code terminal and run the following command:

```bash
cd infra && ./deploy.sh
```
> !NOTE
> If you don't have permissions to execute the .sh script, make sure to change permissions before running it, by using:
> ```bash
> chmod +x ./deploy.sh
> ```

## Run the app locally
1. Open the terminal in your Codespace you used for authentication and run the following command to create a Chainlit Auth Secret - which is used to authenticate with the Chainlit api:

    ```bash
    chainlit create-secret
    ```
1. Copy the secret and save it in the `.env` file the deployment script created in the `src` folder. Add the following line to the `.env` file:

    CHAINLIT_AUTH_SECRET=<your_secret>

1. In the `.env` file also add an envirnoment variable named `AGENT_PASSWORD` with a password easy to remember. This will be asked to the user when the app is started. The new line should look like this:
    
    AGENT_PASSWORD=<your_password>

1. Run F5 to start the app. The app will be available at `http://127.0.0.1:8080/sales/` in your browser.
> !NOTE
> If you don't add `\sales` to the URL, you'll get a 404 error. 

1. You'll be prompted for email address and password. Enter the email address sales@contoso.com and the agent password you set in the `.env` file.

1. You'll be redirected to the Contoso Sales Assistant. Now you can interact with the assistant to get sales information. 