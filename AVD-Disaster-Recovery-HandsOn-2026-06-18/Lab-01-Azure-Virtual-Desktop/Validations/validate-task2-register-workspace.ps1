Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.DesktopVirtualization

# Validation step: 0924e6eb-ca78-43af-8b42-7aa6a20a563a
# Exercise 2 / Task 1 - Register the DR host pool (hp-avd-westus) with the existing ws-avd workspace
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
        # The existing 'ws-avd' workspace must reference an application group whose
        # host pool is 'hp-avd-westus' (or the app group is named 'ag-avd-westus').
        $workspace = Get-AzWvdWorkspace -ResourceGroupName $resourceGroupName -Name 'ws-avd' -ErrorAction SilentlyContinue
        if ($workspace -and $workspace.ApplicationGroupReference) {
            foreach ($agRef in $workspace.ApplicationGroupReference) {
                $agName = ($agRef -split '/')[-1]
                $ag = Get-AzWvdApplicationGroup -ResourceGroupName $resourceGroupName -Name $agName -ErrorAction SilentlyContinue
                if ($ag) {
                    if (($ag.HostPoolArmPath -and $ag.HostPoolArmPath.TrimEnd('/').EndsWith('hp-avd-westus')) -or ($agName -eq 'ag-avd-westus')) {
                        $checkPassed = $true
                        break
                    }
                }
            }
        }
        # -------------------------------------------------------------------------

        if ($checkPassed) {
            $message = @{
                Status  = "Succeeded"
                Message = "The 'ws-avd' workspace references an application group for host pool 'hp-avd-westus'; the DR host pool is registered with the existing workspace."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "The 'ws-avd' workspace does not yet reference an application group for 'hp-avd-westus'. Create a West US application group for hp-avd-westus and add it to the ws-avd workspace's application-group references."
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
