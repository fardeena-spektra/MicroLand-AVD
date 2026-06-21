# Instructor Brief — Azure Virtual Desktop: Disaster Recovery (Lab 01)

**Domain / Level:** Azure Virtual Desktop · Intermediate / Advanced · **Hosting tier A** (native CloudLabs Windows management VM, Windows Server 2022 Datacenter Azure Edition, plus the lab subscription / resource group with a pre-deployed primary AVD environment).
**Target time:** ~90 min work · **120 min** provisioned.
**Cloud field:** `azure` · **Level field:** `Intermediate`.

## Scenario

The candidate is an AVD administrator responsible for business continuity. A **primary AVD environment is already deployed in East US** (workspace `ws-avd`, host pool `hp-avd-eastus` with two session hosts, application group `ag-avd-eastus`, and a geo-redundant storage account with an Azure Files `profiles` share for FSLogix). A **secondary VNet** `vnet-avd-westus` is pre-provisioned for DR. From a Windows management VM the candidate implements and tests a Disaster Recovery solution in West US, in order: deploy a DR host pool, register it with the existing workspace, configure FSLogix on geo-redundant storage, then simulate a regional outage and validate continuity. All work is performed against the lab's **own** subscription / resource group; the validators query Azure directly.

## Environment (pre-deployed by `DeploymentPackage/deploy-01.json` + staged by `bootstrap-01.ps1`)

- A Windows Server 2022 management/jump VM with the candidate toolchain pre-installed: the **Az PowerShell module** and **Az.DesktopVirtualization**.
- **PRIMARY (East US):** `vnet-avd-eastus` (10.10.0.0/16, subnet `hosts`); storage account `stavd<unique>` (**Standard_GRS**) with file share `profiles`; workspace `ws-avd`; pooled host pool `hp-avd-eastus` (BreadthFirst) with a registration token; application group `ag-avd-eastus` (Desktop) registered to `ws-avd`; two session host VMs (`sheast<DeploymentID>0/1`) joined to `hp-avd-eastus` via the AVD agent DSC extension.
- **SECONDARY (West US):** `vnet-avd-westus` (10.20.0.0/16, subnet `hosts`) — empty, ready for the DR session hosts.
- **`C:\LabFiles\README.txt`** describing the four DR tasks and the pre-deployed names.
- The CSE installs tooling only — it does **not** pre-create the DR host pool / application group / DR session host the candidate must build.

## Answer key

All commands run from the management VM after `Connect-AzAccount` and selecting the lab subscription. Substitute the lab resource group for `<RG>`, the storage account for `<SA>`, and a strong password for `<PWD>`.

- **T1 — DR host pool `hp-avd-westus` + registered session host (West US):**
  ```powershell
  # 1) Create the DR host pool
  New-AzWvdHostPool -ResourceGroupName <RG> -Name hp-avd-westus -Location westus `
      -HostPoolType Pooled -LoadBalancerType BreadthFirst -PreferredAppGroupType Desktop `
      -MaxSessionLimit 10
  # 2) Generate a session-host registration token
  $token = New-AzWvdRegistrationInfo -ResourceGroupName <RG> -HostPoolName hp-avd-westus `
      -ExpirationTime (Get-Date).AddHours(4).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
  # 3) Create a West US session host VM on vnet-avd-westus (portal/New-AzVM) and run the
  #    AVD agent installer with $token.Token so it registers into hp-avd-westus.
  #    (Add-AzWvd / DSC 'AddSessionHost' configuration, or the AVD agent + bootloader MSIs.)
  Get-AzWvdSessionHost -ResourceGroupName <RG> -HostPoolName hp-avd-westus   # confirm >= 1
  ```

- **T2 — Register DR host pool with the existing workspace:**
  ```powershell
  # 1) Create a Desktop application group for hp-avd-westus
  $hp = Get-AzWvdHostPool -ResourceGroupName <RG> -Name hp-avd-westus
  New-AzWvdApplicationGroup -ResourceGroupName <RG> -Name ag-avd-westus -Location westus `
      -HostPoolArmPath $hp.Id -ApplicationGroupType Desktop
  # 2) Add it to the EXISTING ws-avd workspace's application-group references
  $ws  = Get-AzWvdWorkspace -ResourceGroupName <RG> -Name ws-avd
  $ag  = Get-AzWvdApplicationGroup -ResourceGroupName <RG> -Name ag-avd-westus
  Update-AzWvdWorkspace -ResourceGroupName <RG> -Name ws-avd `
      -ApplicationGroupReference (@($ws.ApplicationGroupReference) + $ag.Id)
  # (Register-AzWvdApplicationGroup is the equivalent helper.)
  ```

- **T3 — FSLogix on the profiles share + confirm geo-redundancy:**
  ```powershell
  # Confirm the storage account is geo-redundant
  Get-AzStorageAccount -ResourceGroupName <RG> | Select-Object StorageAccountName, @{n='Sku';e={$_.Sku.Name}}
  # On EACH DR session host, set the FSLogix registry profile path to the profiles share:
  $path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
  New-Item  -Path $path -Force | Out-Null
  Set-ItemProperty -Path $path -Name Enabled -Type DWord -Value 1
  Set-ItemProperty -Path $path -Name VHDLocations -Type MultiString `
      -Value "\\<SA>.file.core.windows.net\profiles"
  ```

- **T4 — Simulate a regional outage + confirm DR ready:**
  ```powershell
  # Drain the primary East US session hosts (no new sessions)
  Get-AzWvdSessionHost -ResourceGroupName <RG> -HostPoolName hp-avd-eastus | ForEach-Object {
      $name = ($_.Name -split '/')[-1]
      Update-AzWvdSessionHost -ResourceGroupName <RG> -HostPoolName hp-avd-eastus `
          -Name $name -AllowNewSession:$false
  }
  # (Alternative: Stop-AzVM -ResourceGroupName <RG> -Name sheast<DeploymentID>0 -Force  on each primary host)
  # Confirm DR is ready to accept connections
  Get-AzWvdSessionHost -ResourceGroupName <RG> -HostPoolName hp-avd-westus |
      Where-Object { $_.AllowNewSession -eq $true }
  Get-AzWvdHostPool -ResourceGroupName <RG> -Name hp-avd-westus
  ```

(Full commands and notes are in `LabGuidePackage/Solution-Guide/solution-guide.md`.)

## Scoring rubric (100 pts)

| Item | Pts | Pass criteria (validator) |
|---|---|---|
| T1 DR host pool hp-avd-westus + ≥ 1 session host | 25 | validate-task1-dr-hostpool.ps1 → Succeeded |
| T2 hp-avd-westus app group registered to ws-avd | 25 | validate-task2-register-workspace.ps1 → Succeeded |
| T3 geo-redundant storage backing FSLogix profiles | 25 | validate-task3-fslogix-replication.ps1 → Succeeded |
| T4 primary drained/stopped + DR ready | 25 | validate-task4-outage-continuity.ps1 → Succeeded |

Pass ≥ 50 (at least two tasks fully complete). Full sign-off = 100 with **all four** tasks passing.

## Notes / caveats

- Validators query the **live** Azure subscription / resource group via `Az` / `Az.DesktopVirtualization` cmdlets; they are read-only state checks and safe to re-run. They do **not** use `Invoke-AzVMRunCommand`.
- **AVD permissions & licensing:** the lab identity must hold AVD + Contributor roles and the tenant must be AVD-licensed/enabled. Host pool / session host registration, Entra/AD join, and the AVD agent flow are **intricate and platform-managed**; if the ODL does not grant the right roles or licensing, T1/T2/T4 cannot pass — confirm before the session.
- **FSLogix (T3):** the in-session-host registry configuration (`Enabled` + `VHDLocations`) is verified by **inspection**; the inline validator confirms the geo-redundant storage account that backs the `profiles` share. A candidate who reuses the provided `Standard_GRS` account passes the storage half automatically.
- The pre-deployed primary environment (ws-avd, hp-avd-eastus, ag-avd-eastus, session hosts, storage account) must not be deleted — Exercises 2 and 4 depend on it.
- Session-host registration into a new pool can take a few minutes after the agent installs; re-run the validator if it fails immediately after adding a host.
