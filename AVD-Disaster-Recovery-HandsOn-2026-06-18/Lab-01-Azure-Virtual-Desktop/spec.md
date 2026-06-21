This Package Includes

Deliverables Included in the Package

• Lab Guide
• Master Document
• Inline Validations
• ARM Deployment + Custom Script Extension
• Solution Guide (facilitator-only)
• Instructor Brief (facilitator-only)

Inline Validations

Pre-configured inline validations enabled (4 task validations). Unlike in-VM labs, these validators query the **live Azure subscription / resource group** directly via the `Az` and `Az.DesktopVirtualization` PowerShell cmdlets (the tasks create AVD / Storage / Compute resources, not in-VM state). Each task maps to a validation script keyed by a validation-step UUID; see Validations/Validation.md.

Inline Assessment Questions

Not included in this package (knowledge-check questions are out of scope for this assessment).

Lab Environment Setup & Deployment

Lab provisioning and setup include one or more of the following components:

• ARM template deployment (CloudLabs Windows management/jump VM — Windows Server 2022 Datacenter Azure Edition, Standard_B2s)
• A **pre-deployed PRIMARY Azure Virtual Desktop environment in East US**: virtual network (vnet-avd-eastus), geo-redundant storage account + Azure Files `profiles` share for FSLogix, AVD workspace (ws-avd), pooled host pool (hp-avd-eastus), Desktop application group (ag-avd-eastus), and two registered session host VMs; plus a **secondary West US virtual network** (vnet-avd-westus) for DR
• Custom Script Extension (CSE / PowerShell) — installs the candidate tooling (Az PowerShell module, Az.DesktopVirtualization) and writes a task README; it does not pre-create the DR resources the candidate must build
• Supporting deployment configurations as required

Assessment Profile

• Domain: Azure Virtual Desktop
• Level: Intermediate / Advanced
• Target duration: 120 minutes (120 minutes provisioned)
• Hosting tier: A (native — Azure Windows VM + lab subscription / resource group with a pre-deployed AVD environment)

IMPORTANT — Platform & permissions note

• This lab **pre-deploys a full primary AVD environment**. Azure Virtual Desktop session-host registration, Entra/AD join, and FSLogix are **intricate and platform-managed** flows (the registration token, AVD agent bootstrapper, and DSC configuration are owned by the AVD service); the ARM template models them credibly but real provisioning depends on the AVD service and image availability.
• The candidate identity needs **AVD + Contributor** permissions and a **properly licensed / AVD-enabled tenant** (an appropriate Microsoft 365 / Windows E3/E5 or per-user AVD license). Without these, host pool / session host creation — and the validators — cannot pass.
• Validators query the **live resource group** via `Az` / `Az.DesktopVirtualization` cmdlets and are read-only and safe to re-run.
• The FSLogix in-session-host **registry configuration** (Exercise 3) is verified by **inspection**; the inline validator confirms the geo-redundant storage account that backs the profiles share.
• Inline assessment (knowledge-check) questions are **excluded** from this package.

Scenario & Validation Summary

• Exercise 1 / Task 1 — Deploy the DR host pool hp-avd-westus with a registered session host → validate-task1-dr-hostpool.ps1
• Exercise 2 / Task 1 — Register hp-avd-westus with the existing ws-avd workspace → validate-task2-register-workspace.ps1
• Exercise 3 / Task 1 — FSLogix on the profiles share + geo-redundant storage → validate-task3-fslogix-replication.ps1
• Exercise 4 / Task 1 — Simulate a regional outage and confirm DR continuity → validate-task4-outage-continuity.ps1

Note

• The validators query the live subscription / resource group; all candidate DR resources must be created in the **lab resource group** for validation to pass.
• The pre-deployed primary environment (ws-avd, hp-avd-eastus, ag-avd-eastus, the session hosts, and the storage account) must not be deleted — Exercises 2 and 4 depend on it.

Exclusions

This package does not include:

• Scoring or grading mechanisms beyond pass/fail inline validations
• Inline assessment questions
