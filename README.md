# Sending Azure Service Health Alerts to Teams Channels Using Azure Functions

The ASHWebhookToMessageCardFn.ps1 file contains code to use in a Powershell-based [Azure function](https://azure.microsoft.com/en-us/services/functions/) triggered by an incoming webhook (http trigger).

This code parses the payload of the incoming webhook and creates a [MessageCard](https://docs.microsoft.com/en-us/outlook/actionable-messages/message-card-reference) which is then sent as a webhook to a URI specified in an environment variable for the function.

While this code was built for use with Office365 Teams, the messageCard format is used in other Microsoft tools such as Outlook so this code could probably be adapted to other purposes with a bit of work.

**Future plans:**  In the future this should be updated to use the newer and more flexible [Adaptive Card](https://docs.microsoft.com/en-us/outlook/actionable-messages/adaptive-card) format.

## How to use this (simplified)

1. Create a Powershell function in Azure which uses a http (incoming webhook) trigger.
**[This page](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-function-powershell)** is a good walkthrough of the process using [Visual Studio Code](https://code.visualstudio.com/).
This will prepopulate the function with some skeleton Powershell code in a file named `run.ps1`.
2. Create a system managed identity for the Azure Function App to use.
Access the portal blade for your Function App.
On the left side under **Settings**, select **Identity**.
Toggle **Status** from **Off** to **On**.
See the following section on how to grant this identity access to the blob storage containing the configuration.
3. Replace _all_ code in the `run.ps1` file with the contents of `ASHWebhookToMessageCardFn.ps1` file in this repository.
No changes should be needed.
4. Create an **[Azure Service Health alert](https://docs.microsoft.com/en-us/azure/service-health/alerts-activity-log-service-notifications)** with an **[Action Group](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/action-groups)** that sends a webhook to the trigger URI for the Azure function you created.
***The service health alert must be configured to use the [common alert schema](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/alerts-common-schema) or you will get parse errors from the function when it runs.*** 
5. Get the trigger URI for your new function by clicking on "</> Get Function Url" on the screen which shows the function's code.
The URL should look like `https://<yourfunctionname>.azurewebsites.net/api/...`
6. In Teams, **[create a Webhook Connector](https://docs.microsoft.com/en-us/microsoftteams/platform/concepts/connectors/connectors-using#setting-up-a-custom-incoming-webhook)** for the channel that should receive the alert notifications and make a note of the webhook URI.
7. Follow the direction in the `./config` folder of this repository to configure the Azure Function App to use the generated webhook URI.
9. Use a sample service health alert payload like the one at **[this link](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/activity-log-alerts-webhook#servicehealth)** to trigger your function by calling the URI using curl or invoke-restmethod.
This repository has a copy of the sample payload from this page in the file `SampleServiceHealthAlertWebhookPayload.json`.
A message should appear in your Teams channel that looks like the screenshot at the bottom of this README.
If the screenshot looks good in Teams then the function is working.
9. Wait for an Azure service health alert to trigger your function and check out the result!

The color of the bar at the top of the messageCard varies by the type of alert.
In general, red indicates an urgent active issue, yellow indicates that action is needed, green indicates planned maintenance and blue indicates a message related to resolved or inactive alert such as a RCA posting.
The MessageCard schema is fairly flexible and makes it easy to do things like add an icon to the card as well.

![MessageCard Screenshot](https://github.com/KenHoover/AzureSHStuff/blob/master/SampleHealthAlertCard.PNG?raw=true "Sample MessageCard Output")

## Configure the Storage Account to Use AAD
```Powershell
$subscription = '{{ .nameOfSubscriptionContainingAzureFunctionApp }}'
$resourceGroup = '{{ .nameOfResourceGroupContainingStorageAccountforFunctionApp }}'
$storageAccountName = '{{ .nameOfStorageAccountUsedbyFunctionApp }}'

Set-AzContext -SubscriptionName $subscription

$scope = (Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroup).Id

# get ObjectId of FunctionApp
$functionApp = '{{ .nameOfFunctionApp }}'
$managedSystemId = (Get-AzAdServicePrincipal -DisplayName $functionApp).objectId

$storageAccountRoles = @(
    'Reader and Data Access'
    'Storage Blob Data Contributor'
    'Storage Account Key Operator Service Role'
)

$storageAccountRoles | % {New-AzRoleAssignment -RoleDefinitionName $_ -Scope $scope -ObjectId $managedSystemId}
```