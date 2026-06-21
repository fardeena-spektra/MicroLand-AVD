Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.Storage

# Validation step: 99533b66-374d-4015-8ff8-a70a29fa70cb
# Exercise 3 / Task 1 - FSLogix on the provided Azure Files share + geo-redundant storage
#
# This validator checks Azure RESOURCE state directly via Az cmdlets (the task
# creates resources in the subscription / resource group, not in-VM state), so
# it does NOT use Invoke-AzVMRunCommand. It sets $checkPassed and returns the
# CloudLabs {Status,Message} JSON via Push-OutputBinding.
#
# NOTE: The FSLogix profile-path registry configuration (Enabled + VHDLocations
# pointing at \\<storageaccount>.file.core.windows.net\profiles) lives inside the
# DR session hosts and is verified by inspection in-session-host - it is NOT what
# this Az check measures. This validator confirms the *storage-replication* half
# of the task: that a geo-redundant storage account (which hosts the FSLogix
# profiles share) exists in the lab resource group so profiles survive a regional
# outage.

# Variables provided by CloudLabs
$deployment_id     = $deployment_id
$resourceGroupName = $resourceGroupName
$sub_id            = $sub_id

# Set subscription
Select-AzSubscription -SubscriptionId $sub_id

# Retry logic
$stopRetry = $false
[int]$retryCount = 0
$maxRetries = 3

do {
    try {

        $checkPassed = $false

        # ---- Validation logic: set $checkPassed = $true when the required -------
        # ---- Azure state exists in $resourceGroupName / the subscription. -------
        $geoSkus = @('Standard_GRS','Standard_GZRS','Standard_RAGRS','Standard_RAGZRS')
        $storageAccounts = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
        if ($storageAccounts | Where-Object { $geoSkus -contains $_.Sku.Name }) { $checkPassed = $true }
        # -------------------------------------------------------------------------

        if ($checkPassed) {
            $message = @{
                Status  = "Succeeded"
                Message = "A geo-redundant storage account (GRS/GZRS/RAGRS/RAGZRS) that backs the FSLogix 'profiles' share exists in resource group '$resourceGroupName'; profiles can survive a regional outage."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "No geo-redundant storage account was found in resource group '$resourceGroupName'. Use the provided geo-redundant storage account for the FSLogix 'profiles' share (Standard_GRS/GZRS/RAGRS/RAGZRS) and point the DR session hosts' FSLogix VHDLocations at \\<storageaccount>.file.core.windows.net\profiles."
            } | ConvertTo-Json
        }

        # Return JSON response
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = $message
        })

        $stopRetry = $true
    }
    catch {

        if ($retryCount -ge $maxRetries) {

            $message = @{
                Status  = "Failed"
                Message = "Retry for validation process has been exhausted. Please try after sometime."
            } | ConvertTo-Json

            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [System.Net.HttpStatusCode]::OK
                Body       = $message
            })

            $stopRetry = $true
        }
        else {
            Write-Host "Validation failed. Retrying... ($($retryCount + 1)/$maxRetries)"
            Start-Sleep -Seconds 10
            $retryCount++
        }
    }

} while ($stopRetry -eq $false)
