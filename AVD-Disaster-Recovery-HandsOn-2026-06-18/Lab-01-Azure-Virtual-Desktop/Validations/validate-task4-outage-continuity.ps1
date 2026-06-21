Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.Compute
Import-Module Az.DesktopVirtualization

# Validation step: 635c7a09-2797-4e59-be7e-4c950fe06de7
# Exercise 4 / Task 1 - Simulate a regional outage (drain/stop primary) and confirm DR is ready
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
        # Primary is "out of service" when EITHER all primary session hosts are in
        # drain mode (AllowNewSession = $false) OR the primary session host VMs are
        # stopped/deallocated. DR is "ready" when hp-avd-westus has at least one
        # session host with AllowNewSession = $true.
        $primaryDrained = $false
        $primaryHosts = Get-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName 'hp-avd-eastus' -ErrorAction SilentlyContinue
        if (($primaryHosts | Measure-Object).Count -ge 1) {
            $activePrimary = $primaryHosts | Where-Object { $_.AllowNewSession -eq $true }
            if (($activePrimary | Measure-Object).Count -eq 0) { $primaryDrained = $true }
        }

        if (-not $primaryDrained) {
            # Fall back to checking whether the primary session host VMs are deallocated.
            $primaryVms = Get-AzVM -ResourceGroupName $resourceGroupName -Status -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like 'sheast*' }
            if (($primaryVms | Measure-Object).Count -ge 1) {
                $runningPrimary = $primaryVms | Where-Object { $_.PowerState -eq 'VM running' }
                if (($runningPrimary | Measure-Object).Count -eq 0) { $primaryDrained = $true }
            }
        }

        $drReady = $false
        $drHosts = Get-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName 'hp-avd-westus' -ErrorAction SilentlyContinue
        if ($drHosts | Where-Object { $_.AllowNewSession -eq $true }) { $drReady = $true }

        if ($primaryDrained -and $drReady) { $checkPassed = $true }
        # -------------------------------------------------------------------------

        if ($checkPassed) {
            $message = @{
                Status  = "Succeeded"
                Message = "Primary 'hp-avd-eastus' is out of service (drained or its session host VMs stopped) and DR 'hp-avd-westus' has an available session host accepting new sessions. Continuity is validated."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "Outage continuity not confirmed. Ensure the primary hp-avd-eastus session hosts are drained (AllowNewSession = false) or their VMs are stopped/deallocated, AND that hp-avd-westus has at least one session host with AllowNewSession = true."
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
