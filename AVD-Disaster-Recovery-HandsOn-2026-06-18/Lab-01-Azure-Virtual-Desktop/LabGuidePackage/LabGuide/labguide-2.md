# **Scenario 2: Register the DR Host Pool with a Workspace**

## **Lab Overview**

A host pool is only reachable by users once it is surfaced through an **application group** that is **registered to a workspace**. Your new `hp-avd-westus` pool exists, but users still cannot see it. As the AVD administrator you must publish it through a workspace so DR desktops appear in users' Remote Desktop feed.

This is an **assessment**: the task gives you the **symptom and the required outcome**, not the exact commands. Use the `Az.DesktopVirtualization` module or the portal. After the task, press **Validate** to score it.

> **Note:** You may register the West US application group to the existing `ws-avd` workspace or create and use a dedicated `ws-avd-westus` workspace.

## **Task 1: Publish hp-avd-westus through a workspace**

**Symptom:** The DR host pool has no application group, and no workspace currently exposes the West US desktop resources. Even though the pool is up, users would get no DR desktop in their feed during a failover.

**Required outcome:**

* A **Desktop application group** named **`ag-avd-westus`** exists for **`hp-avd-westus`**.
* The application group is associated with **`hp-avd-westus`**.
* The application group is registered to either:

  * the existing **`ws-avd`** workspace, or
  * a dedicated **`ws-avd-westus`** workspace.

Create the application group bound to `hp-avd-westus`, then register it to a supported workspace. The validator verifies that `ag-avd-westus` is associated with `hp-avd-westus` and that the application group is registered to either `ws-avd` or `ws-avd-westus`.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
>
> * Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> * If not, carefully read the error message and retry the step, following the instructions in the lab guide.

<validation step="a4470170-4927-4b9f-a114-38626f9383c9" />


**If you need any assistance, please contact us at [cloudlabs-support@spektrasystems.com](mailto:cloudlabs-support@spektrasystems.com). We are available 24/7 to help you out.**
