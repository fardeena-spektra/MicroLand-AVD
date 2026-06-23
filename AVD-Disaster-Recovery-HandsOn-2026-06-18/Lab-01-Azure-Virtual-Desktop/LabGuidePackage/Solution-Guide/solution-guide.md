# CloudLabs by Spektra Systems | Facilitator Solution Guide (NOT for candidates)

## Azure Virtual Desktop — Disaster Recovery (Lab 01): Answer Key + Walkthrough

This document mirrors the candidate exercise order. Each task lists the recommended approach, the exact commands (`Az.DesktopVirtualization` / `Az.Storage` / `Az.Compute`), the expected result, and the validation expectation. All work is performed from the Windows management VM against the lab's own Azure subscription / resource group. The **primary** AVD environment (East US) is pre-deployed; the candidate builds the **DR** environment (West US).

> **Setup (once):** RDP into the management VM, then connect to the lab subscription:
> ```powershell
> Connect-AzAccount           # use the Azure portal credentials on the Environment tab
> Get-AzContext               # confirm subscription + tenant
> (Get-AzResourceGroup).ResourceGroupName     # note the lab resource group -> use as <RG>
> (Get-AzStorageAccount -ResourceGroupName <RG>).StorageAccountName   # the FSLogix storage account -> <SA>
> ```
> Substitute the lab resource group for `<RG>`, the storage account for `<SA>`, and a strong password for `<PWD>`.

---

## Exercise 1 / Task 1 — Deploy the DR host pool hp-avd-westus with a registered session host

**Objective:** A host pool `hp-avd-westus` exists in the lab resource group with at least one registered session host.

**Fix (Az.DesktopVirtualization):**

```powershell
# 1) Create the DR host pool in West US
New-AzWvdHostPool -ResourceGroupName <RG> -Name hp-avd-westus -Location westus `
    -HostPoolType Pooled -LoadBalancerType BreadthFirst -PreferredAppGroupType Desktop `
    -MaxSessionLimit 10

# 2) Generate a session-host registration token (valid future expiry)
$token = New-AzWvdRegistrationInfo -ResourceGroupName <RG> -HostPoolName hp-avd-westus `
    -ExpirationTime (Get-Date).AddHours(4).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')

# 3) Deploy a West US session host VM (Windows 11 multi-session) on vnet-avd-westus, then run
#    the AVD agent + bootloader with $token.Token so the VM registers into hp-avd-westus.
#    Portal: Host pool > Session hosts > Add. PowerShell: New-AzVM then the AVD agent MSIs /
#    the 'AddSessionHost' DSC configuration with registrationInfoToken = $token.Token.
```

**Alternative (Azure CLI):**

```bash
az desktopvirtualization hostpool create -g <RG> -n hp-avd-westus --location westus \
    --host-pool-type Pooled --load-balancer-type BreadthFirst --preferred-app-group-type Desktop \
    --max-session-limit 10
az desktopvirtualization hostpool update -g <RG> -n hp-avd-westus \
    --registration-info expiration-time="2026-06-19T00:00:00.000Z" registration-token-operation=Update
```

**Expected result:** `Get-AzWvdHostPool -ResourceGroupName <RG> -Name hp-avd-westus` returns the pool, and `Get-AzWvdSessionHost -ResourceGroupName <RG> -HostPoolName hp-avd-westus` returns ≥ 1 host.

**Validation:** `validate-task1-dr-hostpool.ps1` confirms `hp-avd-westus` exists **and** has at least one session host.

---

## Exercise 2 / Task 1 — Publish the DR Host Pool Through a Workspace

**Objective:** A West US Desktop application group (`ag-avd-westus`) exists for `hp-avd-westus` and is registered to a workspace so the DR desktop is available in the Remote Desktop feed.

**Fix (Az.DesktopVirtualization):**

```powershell
# 1) Create the Desktop application group bound to hp-avd-westus
$hp = Get-AzWvdHostPool -ResourceGroupName <RG> -Name hp-avd-westus

New-AzWvdApplicationGroup `
    -ResourceGroupName <RG> `
    -Name ag-avd-westus `
    -Location westus `
    -HostPoolArmPath $hp.Id `
    -ApplicationGroupType Desktop

# 2) Create a West US workspace for DR
New-AzWvdWorkspace `
    -ResourceGroupName <RG> `
    -Name ws-avd-westus `
    -Location westus `
    -FriendlyName "AVD DR Workspace" `
    -Description "West US DR Workspace"

# 3) Register the application group with the workspace
$ag = Get-AzWvdApplicationGroup `
    -ResourceGroupName <RG> `
    -Name ag-avd-westus

Update-AzWvdWorkspace `
    -ResourceGroupName <RG> `
    -Name ws-avd-westus `
    -ApplicationGroupReference @($ag.Id)
```

**Alternative (Azure CLI):**

```bash
hpId=$(az desktopvirtualization hostpool show \
    -g <RG> \
    -n hp-avd-westus \
    --query id -o tsv)

az desktopvirtualization applicationgroup create \
    -g <RG> \
    -n ag-avd-westus \
    --location westus \
    --host-pool-arm-path "$hpId" \
    --application-group-type Desktop

az desktopvirtualization workspace create \
    -g <RG> \
    -n ws-avd-westus \
    --location westus \
    --friendly-name "AVD DR Workspace"

agId=$(az desktopvirtualization applicationgroup show \
    -g <RG> \
    -n ag-avd-westus \
    --query id -o tsv)

az desktopvirtualization workspace update \
    -g <RG> \
    -n ws-avd-westus \
    --application-group-references "$agId"
```

**Expected result:**

```powershell
Get-AzWvdWorkspace `
    -ResourceGroupName <RG> `
    -Name ws-avd-westus |
    Select -ExpandProperty ApplicationGroupReference
```

returns a reference to:

```text
ag-avd-westus
```

and:

```powershell
Get-AzWvdApplicationGroup `
    -ResourceGroupName <RG> `
    -Name ag-avd-westus
```

shows:

```text
HostPoolArmPath ... hp-avd-westus
```

**Validation:** `validate-task2-register-workspace.ps1` checks that the `ag-avd-westus` application group exists and is associated with the `hp-avd-westus` host pool. The validator then verifies that either `ws-avd` or `ws-avd-westus` references `ag-avd-westus`. Validation succeeds when the West US application group is registered to either workspace.

---

## Exercise 3 / Task 1 — FSLogix on the profiles share + geo-redundant storage

**Objective:** The DR session hosts' FSLogix profile path points to `\\<SA>.file.core.windows.net\profiles`, and the storage account is geo-redundant.

**Fix — confirm geo-redundancy (Az.Storage):**

```powershell
Get-AzStorageAccount -ResourceGroupName <RG> |
    Select-Object StorageAccountName, @{n='Sku';e={$_.Sku.Name}}, PrimaryLocation, SecondaryLocation
# The provided account is Standard_GRS (geo-redundant). If you created your own share, ensure the
# account SKU is Standard_GRS / GZRS / RAGRS / RAGZRS.
```

**Fix — FSLogix profile path on EACH DR session host (registry):**

```powershell
$path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
New-Item  -Path $path -Force | Out-Null
Set-ItemProperty -Path $path -Name Enabled      -Type DWord       -Value 1
Set-ItemProperty -Path $path -Name VHDLocations -Type MultiString -Value "\\<SA>.file.core.windows.net\profiles"
# Grant the session-host computer accounts / users access to the 'profiles' share (SMB share +
# NTFS permissions) per the FSLogix profile-container guidance.
```

**Expected result:** `Get-AzStorageAccount` shows a geo-redundant SKU; the DR session hosts have `Enabled=1` and `VHDLocations` set to the `profiles` UNC path.

**Validation:** `validate-task3-fslogix-replication.ps1` confirms a geo-redundant storage account (GRS/GZRS/RAGRS/RAGZRS) exists in the lab resource group. The in-session-host FSLogix registry values are verified by **inspection** (not by the Az check).

---

## Exercise 4 / Task 1 — Simulate a regional outage and validate continuity

**Objective:** The primary `hp-avd-eastus` session hosts are drained (or stopped) and the DR `hp-avd-westus` pool has an available session host accepting new sessions.

**Fix — drain the primary (Az.DesktopVirtualization):**

```powershell
Get-AzWvdSessionHost -ResourceGroupName <RG> -HostPoolName hp-avd-eastus | ForEach-Object {
    $name = ($_.Name -split '/')[-1]
    Update-AzWvdSessionHost -ResourceGroupName <RG> -HostPoolName hp-avd-eastus `
        -Name $name -AllowNewSession:$false
}
```

**Alternative — stop/deallocate the primary session host VMs (Az.Compute):**

```powershell
Get-AzVM -ResourceGroupName <RG> | Where-Object { $_.Name -like 'sheast*' } | ForEach-Object {
    Stop-AzVM -ResourceGroupName <RG> -Name $_.Name -Force
}
```

**Confirm DR is ready:**

```powershell
Get-AzWvdSessionHost -ResourceGroupName <RG> -HostPoolName hp-avd-westus |
    Where-Object { $_.AllowNewSession -eq $true }
Get-AzWvdHostPool -ResourceGroupName <RG> -Name hp-avd-westus
```

**Expected result:** No `hp-avd-eastus` session host accepts new sessions (or the primary VMs are deallocated), and at least one `hp-avd-westus` host has `AllowNewSession = $true`.

**Validation:** `validate-task4-outage-continuity.ps1` confirms the primary is drained/stopped **and** the DR pool has an available, session-accepting host.

---

### Facilitator Notes

- All four validators query Azure RESOURCE state directly via `Az` / `Az.DesktopVirtualization` cmdlets (no `Invoke-AzVMRunCommand`). HTTP is always `OK`; pass/fail lives in the JSON `Status` field. They are read-only and safe to re-run.
- Every candidate DR resource must be created in the **lab resource group**. The pre-deployed primary environment (ws-avd, hp-avd-eastus, ag-avd-eastus, session hosts, storage account) must remain — Exercises 2 and 4 depend on it.
- **AVD licensing/permissions** are required for session-host registration and Entra/AD join; if the ODL profile lacks AVD + Contributor roles or AVD licensing, T1/T2/T4 cannot pass.
- Session-host registration into a new pool can lag a few minutes after the agent installs — re-run the validator if it fails immediately after adding a host.
- T3's storage half passes automatically when the candidate uses the provided `Standard_GRS` account; the FSLogix registry config is confirmed by inspecting the DR session hosts.
