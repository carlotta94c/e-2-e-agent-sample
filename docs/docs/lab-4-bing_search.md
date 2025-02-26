## Introduction

Grounding conversations with Bing is one of several tools provided by the Azure AI Agent Service. Grounding with Bing allows your app to search for information relevant to the conversation. For example, you might want to search for competitive product information.

## Lab Exercise

In this lab, you'll enable Bing Grounding to provide competitive sales analysis of Contoso products and categories.

### Grounding with Bing Search Service

You'll need to create a **Grounding with Bing Search Service** resource in the Azure portal and connect it to the Azure AI Foundry portal.

Follow these steps to create a Grounding with Bing Search Resource:

1. [Click to create a Grounding with Bing Search Resource](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/Microsoft.BingGroundingSearch){:target="_blank"}.

    !!! Note
        You may need to sign in to your Azure account and or clear the welcome screen to access the Azure portal.

1. Select **Create**.
1. Select the **rg-agent-workshop** resource group from the drop-down list.
1. Name the resource as follows:

    ```text
    grounding-with-bing-search
    ```

1. Select the **Grounding with Bing Search** pricing tier.
1. Confirm **I confirm I have read and understood the notice above**.
1. Select **Review + create**.
1. Select **Create**.
1. Once the deployment is complete, select **Go to resource**.

### Get the Bing Search API Key

1. Ensure the **grounding-with-bing-search** resource is selected.
1. From the side-bar menu, select **RESOURCE MANAGEMENT**.
1. Select the **Keys**.
1. Copy the **Key 1**.
1. Select the **Overview** from the side-bar menu.
1. Select the **Go to Azure AI Foundry Portal** button.
<!-- 1. Select **Sign in** and enter your Azure account credentials. -->

### Create a Bing Search Connection

Next, we will create a Bing Search connection in the Azure AI Foundry portal. This connection enables the agent app to access the Bing Search service using the agent **Grounding-with-Bing-Search**.

To create a Bing Search connection in the Azure AI Foundry portal, follow these steps:

1. Select the project, its name starts with **aip**.
2. From the sidebar menu, click the **Management Center** tab. The tab is pinned at the **bottom** of the sidebar.

### Add an API Key

1. From the side-bar menu, select **Connected resources**.
1. Click **+ New Connection**.
1. Scroll to the bottom of the connection types and select **API Key**.
1. Paste the **API Key** you previously copied into the **Key** field.
1. For the **Endpoint**, enter

    ```text
    https://api.bing.microsoft.com/
    ```

1. Set the connection name to

    ```text
    Grounding-with-Bing-Search
    ```

1. Ensure the Access setting remains as **Shared to all projects**.
1. Click "Add Connection"

For more information, visit the [Grounding with Bing Search](https://learn.microsoft.com/en-us/azure/ai-services/agents/how-to/tools/bing-grounding){:target="_blank"} documentation.

### Enable Grounding with Bing Search in the Agent App

1. Open the `main.py`.

1. **Uncomment** the following lines by removing the **"# "** characters

    ```python
    # INSTRUCTIONS_FILE = "instructions/instructions_bing_grounding.txt"
    # bing_connection = project_client.connections.get(connection_name=BING_CONNECTION_NAME)
    # bing_grounding = BingGroundingTool(bing_connection)
    # toolset.add(bing_grounding)
    ```

    !!! warning
        The lines to be uncommented are not adjacent. When removing the # character, ensure you also delete the space that follows it.

1. Review the code in the `main.py` file.

    After uncommenting, your code should look like this:

    ``` python
    INSTRUCTIONS_FILE = "instructions/instructions_function_calling.txt"
    INSTRUCTIONS_FILE = "instructions/instructions_code_interpreter.txt"
    INSTRUCTIONS_FILE = "instructions/instructions_file_search.txt"
    INSTRUCTIONS_FILE = "instructions/instructions_bing_grounding.txt"


    async def add_agent_tools():
        """Add tools for the agent."""

        # Add the functions tool
        toolset.add(functions)

        # Add the code interpreter tool
        code_interpreter = CodeInterpreterTool()
        toolset.add(code_interpreter)

        # Add the tents data sheet to a new vector data store
        vector_store = await utilities.create_vector_store(
            project_client,
            files=[TENTS_DATA_SHEET_FILE],
            vector_name_name="Contoso Product Information Vector Store",
        )
        file_search_tool = FileSearchTool(vector_store_ids=[vector_store.id])
        toolset.add(file_search_tool)

        # Add the Bing grounding tool
        bing_connection = await project_client.connections.get(connection_name=BING_CONNECTION_NAME)
        bing_grounding = BingGroundingTool(connection_id=bing_connection.id)
        toolset.add(bing_grounding)
    ```

### Review the Instructions

The **instructions/instructions_bing_grounding.txt** file provides guidance on how the LLM should use Bing search for grounding purposes. It ensures that queries remain relevant to Contoso and maintain a focus on contextually appropriate searches.

### Run the Agent App

1. Press <kbd>F5</kbd> to run the app.
2. In the terminal, the app starts, and the agent app will prompt you to **Enter your query**.

### Start a Conversation with the Agent

The agent combines data from the Contoso sales database, the Tents Data Sheet, and Bing Search to provide comprehensive responses, so the results will vary depending on the query.

1. **What beginner tents do we sell?**
2. **What beginner tents do our competitors sell and include prices?**
3. **Show as a bar chart**
4. **Show the tents we sell by region that are a similar price to our competitors beginner tents.**
5. **Download the data**

## Stop the Agent App

When you're done, type **exit**, or press <kbd>Shift</kbd>+<kbd>F5</kbd> to stop the agent app.
