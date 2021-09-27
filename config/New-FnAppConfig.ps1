$configFile = New-TemporaryFile

$config = Get-Content './config.json' -Encoding utf8 | ConvertFrom-Json -Depth 15

$subscriptions = Get-AzSubscription -WarningAction SilentlyContinue
$subscriptionsArray = @()
$subscriptions | ForEach-Object {
    $subscriptionsArray += @{
        Name = $_.Name
        Id = $_.Id
    }
}

$config.Production.subscriptions = $subscriptionsArray
$config.Development.subscriptions = $subscriptionsArray
$config.Staging.subscriptions = $subscriptionsArray

($config | ConvertTo-Json -Depth 15 | Set-Content -Path $configFile.FullName -Encoding utf8 -Force)

Write-Output $configFile
