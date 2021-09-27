# Creating Configuration File for `ASHWebhookToMessageCardFn.ps1`

Powershell does not support reading configuration items from the Azure App Configuration Service.

A configuration file containing the mapping of Azure subscription IDs to subscription names and the Teams webhook URIs must be placed into the Azure Blob Storage container associated with the Azure Function App.

## Add the Webhook URIs to  `config.json.template`
```Powershell
cp  config.json.template config.json
```

Replace the entries under `"webhookIntegrations"` for each of the application environments with the appropriate Teams webhooks.

### `config.json` Copied from `config.json.template`
```json
{
    "Production": {
        "subscriptions": [],
        "webhookIntegrations": [
            {
                "channel":"{{ .productionTeamsChannelName }}",
                "uri":"{{ .productionTeamsChannelUri }}"
            }
        ]
    },
.
.
.
```

### `config.json` Modified with Webhook URIs
```json
# Values for webhook inserted
{
    "Production": {
        "subscriptions": [],
        "webhookIntegrations": [
            {
                "channel":"Teams channel name",
                "uri":"https://outlook.office.com/webhook/<redacted_webhook>"
            }
        ]
    },
.
.
.
```

## Generate the Subscription ID to Name mappings
```Powershell
Connect-AzAccount

$configurationFile = ./New-FnAppConfig.ps1
```

## Upload `config.json` to Blob Storage
```Powershell

$storageAccountName = "{{ .storageAccountName }}"

$storageContext = New-AzStorageContext -UseConnectedAccount -StorageAccountName $storageAccountName

Set-AzStorageBlobContent -Context $StorageContext -Container 'data' -File $configurationFile.Fullname -blob config.json

```