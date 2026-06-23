Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.DesktopVirtualization

# Validation step: 0924e6eb-ca78-43af-8b42-7aa6a20a563a
# Exercise 2 / Task 1 - Register the DR host pool (hp-avd-westus) with a workspace
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

        # ---- Validation logic -----------------------------------------------
        # Pass if:
        # - Application Group 'ag-avd-westus' exists
        # - AND it is associated with either:
        #     * ws-avd
        #     * ws-avd-westus
        # ---------------------------------------------------------------------

        $ag = Get-AzWvdApplicationGroup `
            -ResourceGroupName $resourceGroupName `
            -Name 'ag-avd-westus' `
            -ErrorAction SilentlyContinue

        if ($ag) {

            $workspaces = @()

            $wsEast = Get-AzWvdWorkspace `
                -ResourceGroupName $resourceGroupName `
                -Name 'ws-avd' `
                -ErrorAction SilentlyContinue

            if ($wsEast) {
                $workspaces += $wsEast
            }

            $wsWest = Get-AzWvdWorkspace `
                -ResourceGroupName $resourceGroupName `
                -Name 'ws-avd-westus' `
                -ErrorAction SilentlyContinue

            if ($wsWest) {
                $workspaces += $wsWest
            }

            foreach ($workspace in $workspaces) {

                if (-not $workspace.ApplicationGroupReference) {
                    continue
                }

                foreach ($agRef in $workspace.ApplicationGroupReference) {

                    $agName = ($agRef -split '/')[-1]

                    if ($agName -eq 'ag-avd-westus') {
                        $checkPassed = $true
                        break
                    }
                }

                if ($checkPassed) {
                    break
                }
            }
        }

        # ---------------------------------------------------------------------

        if ($checkPassed) {
            $message = @{
                Status  = "Succeeded"
                Message = "The application group 'ag-avd-westus' is successfully associated with a workspace."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "The application group 'ag-avd-westus' was not found associated with either 'ws-avd' or 'ws-avd-westus'."
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