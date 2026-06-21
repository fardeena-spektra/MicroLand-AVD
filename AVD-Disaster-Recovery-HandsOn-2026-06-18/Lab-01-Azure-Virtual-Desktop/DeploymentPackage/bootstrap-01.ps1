<#
================================================================================
 bootstrap-01.ps1  -  CloudLabs provisioning baseline for
 Lab 01 (Azure Virtual Desktop - Disaster Recovery)

 PURPOSE
   Executed once at deployment time by the Windows Custom Script Extension on the
   lab management/jump VM. It installs the tooling the candidate needs to perform
   the four AVD Disaster Recovery tasks against the lab's own subscription /
   resource group:
     - Az PowerShell module (Az.Accounts, Az.Resources, Az.Network, Az.Storage, ...)
     - Az.DesktopVirtualization module (Get-/New-/Update-AzWvd* cmdlets)

   The PRIMARY AVD environment (East US) is pre-deployed by the ARM template:
   resource group, VNet, Storage Account + 'profiles' Azure Files share, the
   ws-avd workspace, the hp-avd-eastus host pool, the ag-avd-eastus application
   group, and two registered session hosts. A SECONDARY VNet (vnet-avd-westus)
   is pre-provisioned for DR. The candidate builds and tests the DR solution.

   This script only stages the toolchain and a README. Every step is wrapped in
   try/catch and writes progress with Write-Host so a single failing installer
   never hard-fails the whole deployment.

 NOTE
   The candidate works against AZURE resources (AVD host pools, session hosts,
   workspace, application groups, storage). Validators query Azure directly via
   Az / Az.DesktopVirtualization cmdlets - nothing in this script needs to seed
   in-VM state.
================================================================================
#>

param(
    [string]$AzureUserName,
    [string]$AzurePassword,
    [string]$AzureTenantID,
    [string]$AzureSubscriptionID,
    [string]$odlId,
    [string]$DeploymentID
)

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
$LogFile = 'C:\cloudlabs-bootstrap.log'

function Write-Log {
    param([string]$Message)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "$ts  $Message"
    try { "$ts  $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { }
}

Write-Log "Bootstrap starting for DeploymentID '$DeploymentID' (ODL '$odlId')."

# Make TLS 1.2 the default so the gallery / downloads succeed on Windows Server.
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch { Write-Log "Could not set TLS 1.2: $($_.Exception.Message)" }

# ------------------------------------------------------------------------------
# 1) NuGet provider + PSGallery trust (prerequisite for Install-Module)
# ------------------------------------------------------------------------------
try {
    Write-Log "Ensuring NuGet package provider and trusting PSGallery."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    Write-Log "NuGet provider ready; PSGallery trusted."
} catch {
    Write-Log "NuGet/PSGallery setup warning: $($_.Exception.Message)"
}

# ------------------------------------------------------------------------------
# 2) Az PowerShell module (used by the candidate AND by the validators)
# ------------------------------------------------------------------------------
try {
    Write-Log "Installing the Az PowerShell module (this can take several minutes)."
    Install-Module -Name Az -Scope AllUsers -Force -AllowClobber -ErrorAction Stop
    Write-Log "Az PowerShell module installed."
} catch {
    Write-Log "Az module install warning: $($_.Exception.Message)"
}

# ------------------------------------------------------------------------------
# 3) Az.DesktopVirtualization module (Get-/New-/Update-AzWvd* cmdlets for AVD)
# ------------------------------------------------------------------------------
try {
    Write-Log "Installing the Az.DesktopVirtualization PowerShell module."
    Install-Module -Name Az.DesktopVirtualization -Scope AllUsers -Force -AllowClobber -ErrorAction Stop
    Write-Log "Az.DesktopVirtualization module installed."
} catch {
    Write-Log "Az.DesktopVirtualization module install warning: $($_.Exception.Message)"
}

# ------------------------------------------------------------------------------
# 4) Candidate README describing the DR tasks and the pre-deployed environment
# ------------------------------------------------------------------------------
try {
    Write-Log "Writing C:\LabFiles\README.txt."
    New-Item -Path 'C:\LabFiles' -ItemType Directory -Force | Out-Null
    $readme = @"
================================================================================
 Azure Virtual Desktop - Disaster Recovery Assessment (Lab 01)
================================================================================

You are working from this Windows management/jump VM. A PRIMARY Azure Virtual
Desktop environment is ALREADY DEPLOYED in East US in the lab resource group.
Your job is to implement and test a DISASTER RECOVERY solution in West US.

Sign in with the Azure credentials shown on the lab Environment tab, then connect
Az PowerShell to the lab subscription before you start:

    Connect-AzAccount            # use the Azure portal credentials (Environment tab)
    Get-AzContext                # confirm the subscription / tenant
    Get-AzResourceGroup          # note the lab resource group name (use as <RG>)

PRE-DEPLOYED PRIMARY ENVIRONMENT (do NOT recreate it):
  - Resource group ............ the lab resource group (Get-AzResourceGroup)
  - Primary VNet .............. vnet-avd-eastus (East US, 10.10.0.0/16, subnet 'hosts')
  - Secondary VNet (for DR) ... vnet-avd-westus (West US, 10.20.0.0/16, subnet 'hosts')
  - AVD workspace ............. ws-avd
  - Primary host pool ......... hp-avd-eastus (Pooled, BreadthFirst) + 2 session hosts
  - Primary application group . ag-avd-eastus (Desktop) -> registered to ws-avd
  - Storage account ........... stavd<unique> (Standard_GRS, geo-redundant)
  - FSLogix profile share ..... \\stavd<unique>.file.core.windows.net\profiles

YOUR DR TASKS (build everything in the SAME lab resource group):

  Exercise 1 - Deploy the DR host pool
     Create a SECOND AVD host pool 'hp-avd-westus' in West US and add at least one
     session host VM to it (attach the West US session host(s) to vnet-avd-westus).

  Exercise 2 - Register the DR host pool with the existing workspace
     Create a West US application group (e.g. ag-avd-westus) for hp-avd-westus and
     register it with the EXISTING ws-avd workspace (add it to the workspace's
     application-group references).

  Exercise 3 - FSLogix profiles + storage replication
     Point the FSLogix profile path on the DR session hosts at the provided Azure
     Files share (\\<storageaccount>.file.core.windows.net\profiles) and confirm the
     storage account is geo-redundant (Standard_GRS / GZRS / RAGRS) so profiles
     survive a regional outage.

  Exercise 4 - Simulate a regional outage and validate continuity
     Place the PRIMARY hp-avd-eastus session hosts in drain mode
     (AllowNewSession = false) or stop/deallocate the primary session host VMs,
     and confirm the DR host pool hp-avd-westus has an available session host
     (AllowNewSession = true) ready to accept connections.

Tooling pre-installed on this VM: Az PowerShell module, Az.DesktopVirtualization.
Verify your work with: Get-AzWvdHostPool, Get-AzWvdSessionHost, Get-AzStorageAccount.

Use the Validate button on each exercise to score your work - the validators query
Azure directly, so make sure every resource lives in the lab resource group.
================================================================================
"@
    Set-Content -Path 'C:\LabFiles\README.txt' -Value $readme -Encoding UTF8
    Write-Log "README written."
} catch {
    Write-Log "README write warning: $($_.Exception.Message)"
}

Write-Log "Bootstrap complete."
