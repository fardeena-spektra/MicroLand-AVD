# Scenario 1: Deploy the Disaster Recovery Host Pool

### Estimated Duration: 30 Minutes

## Lab Overview

The production AVD environment runs entirely in **East US** (`hp-avd-eastus`). If that region became unavailable, users would have nowhere to connect. As the AVD administrator you must stand up a **second host pool in West US** so the service can fail over to another region.

This is an **assessment**: each task gives you the **symptom and the required outcome** — not the steps. Decide host pool type, sizing, and the session host image yourself, then build it. After the task, press **Validate** to score it.

> **Note:** Connect to the management VM over RDP, sign in to the lab subscription with `Connect-AzAccount`, and confirm you are in the lab resource group before you start. Build the new resources in the **same lab resource group** as the pre-deployed primary environment, and attach the new session host(s) to the pre-provisioned `vnet-avd-westus` network.

## Task 1: Create the West US host pool with a registered session host

**Symptom:** All AVD capacity lives in East US. There is no host pool in a second region, so a regional outage would take the desktop service down with no failover target.

**Required outcome:** A host pool named **`hp-avd-westus`** exists in the lab resource group, and it has **at least one session host registered** to it (a West US session host VM joined to the pool).

Create the `hp-avd-westus` host pool (Pooled is fine, matching the primary), generate a registration token, then add one or more session host VMs in West US — attached to `vnet-avd-westus` — and register them with the pool. The validator checks that the host pool exists **and** that `Get-AzWvdSessionHost` returns at least one session host for it.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.

<validation step="826b386b-13a0-4c44-b0a4-2dbb86cebb58" />


**If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.**


