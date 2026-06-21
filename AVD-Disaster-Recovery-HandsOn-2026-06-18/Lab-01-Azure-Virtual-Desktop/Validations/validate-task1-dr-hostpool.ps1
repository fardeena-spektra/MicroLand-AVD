Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.DesktopVirtualization

# Validation step: ffdbeaae-7635-457d-823b-e1185d61360b
# Exercise 1 / Task 1 - Deploy the DR host pool hp-avd-westus with a registered session host
#
# This validator checks Azure RESOURCE state directly via Az cmdlets (the task
# creates resources in the subscription / resource group, not in-VM state), so
# it does NOT use Invoke-AzVMRunCommand. It sets $checkPassed and returns the
# CloudLabs {Status,Message} JSON via Push-OutputBinding.

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
        $drHostPool = Get-AzWvdHostPool -ResourceGroupName $resourceGroupName -Name 'hp-avd-westus' -ErrorAction SilentlyContinue
        if ($drHostPool) {
            $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName 'hp-avd-westus' -ErrorAction SilentlyContinue
            if (($sessionHosts | Measure-Object).Count -ge 1) { $checkPassed = $true }
        }
        # -------------------------------------------------------------------------

        if ($checkPassed) {
            $message = @{
                Status  = "Succeeded"
                Message = "DR host pool 'hp-avd-westus' exists in resource group '$resourceGroupName' with at least one registered session host."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "No DR host pool 'hp-avd-westus' with a registered session host was found in resource group '$resourceGroupName'. Create the West US host pool and add at least one session host to it."
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
