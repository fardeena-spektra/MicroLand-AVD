# Exercise 2: Register the DR Host Pool with the Existing Workspace

### Estimated Duration: 30 Minutes

## Lab Overview

A host pool is only reachable by users once it is surfaced through an **application group** that is **registered to a workspace**. Your new `hp-avd-westus` pool exists, but users still cannot see it. As the AVD administrator you must publish it through the **existing** `ws-avd` workspace so DR desktops appear in the same Remote Desktop feed users already have.

This is an **assessment**: the task gives you the **symptom and the required outcome**, not the exact commands. Use the `Az.DesktopVirtualization` module or the portal. After the task, press **Validate** to score it.

> **Note:** Do **not** create a new workspace. Reuse the pre-deployed `ws-avd` workspace and add your West US application group to its application-group references.

## Task 1: Publish hp-avd-westus through the existing workspace

**Symptom:** The DR host pool has no application group, and nothing for West US is registered to `ws-avd`. Even though the pool is up, users would get no DR desktop in their feed during a failover.

**Required outcome:**

- A **Desktop application group** (for example **`ag-avd-westus`**) exists for **`hp-avd-westus`**.
- That application group is **registered to the existing `ws-avd` workspace** (it appears in the workspace's application-group references).

Create the application group bound to `hp-avd-westus`, then add it to `ws-avd`'s `ApplicationGroupReference` list (alongside the existing `ag-avd-eastus`). The validator inspects `ws-avd`, walks its referenced application groups, and confirms one of them points at the `hp-avd-westus` host pool.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="0924e6eb-ca78-43af-8b42-7aa6a20a563a" />
