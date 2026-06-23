# Scenario 3: Configure FSLogix Profiles and Verify Storage Replication

### Estimated Duration: 30 Minutes

## Lab Overview

For DR to be useful, users must get **their own profile** when they land on a West US session host. FSLogix profile containers solve this by storing each user's profile on an SMB file share. The profiles must also survive a regional failure, which means the share has to live on **geo-redundant** storage. As the AVD administrator you must point the DR session hosts at the provided Azure Files share and confirm the storage is replicated across regions.

This is an **assessment**: the task gives you the **symptom and the required outcome**, not the exact commands. After the task, press **Validate** to score it.

> **Note:** The Azure Files share `profiles` is already provided on the pre-deployed storage account (`stavd<unique>`). Do not create a new storage account — use the provided one, and confirm its replication setting.

## Task 1: Point FSLogix at the profiles share and confirm geo-redundancy

**Symptom:** DR session hosts have no shared profile location, so users would get a fresh temporary profile after failover. The team also needs proof that profile data would survive the loss of the primary region.

**Required outcome:**

- The **FSLogix profile path** on the DR session hosts points to the provided Azure Files share — **`\\<storageaccount>.file.core.windows.net\profiles`** (the FSLogix `VHDLocations` value).
- The storage account hosting that share uses **geo-redundant replication** — its SKU is one of **`Standard_GRS`**, **`Standard_GZRS`**, **`Standard_RAGRS`**, or **`Standard_RAGZRS`** — so profiles survive a regional outage.

Set the FSLogix `Enabled` and `VHDLocations` registry values on the DR session hosts to the `profiles` UNC path, and verify the storage account replication with `Get-AzStorageAccount`. The validator confirms a **geo-redundant** storage account exists in the lab resource group; the FSLogix registry configuration on the session hosts is verified by inspection (see the note below).

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.

<validation step="7eeefb62-9939-474a-8826-fb0a4e4f4796" />


**If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.**