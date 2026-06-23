# **Scenario 4: Simulate a Regional Outage and Validate Continuity**

## **Lab Overview**

A DR design is only credible once it has been **tested**. With the West US host pool built, registered, and backed by geo-redundant FSLogix profiles, you must now rehearse a failover: take the **primary** East US capacity out of service and prove the **DR** host pool is ready to carry user connections. As the AVD administrator you simulate a regional outage and confirm continuity.

This is an **assessment**: the task gives you the **symptom and the required outcome**, not the exact commands. After the task, press **Validate** to score it.

> **Note:** This is a controlled drill. "Taking the primary out of service" means draining it (`AllowNewSession = false`) or stopping/deallocating its session host VMs — you do not delete anything.

## **Task 1: Drain the primary and confirm the DR pool is ready**

**Symptom:** A regional outage in East US has been declared. New sessions must stop landing on the primary hosts, and the West US DR pool must be confirmed ready to accept users — but nothing has been switched over yet.

**Required outcome:**

- The **primary** `hp-avd-eastus` session hosts are taken out of service — either placed in **drain mode** (`AllowNewSession = false`) **or** their VMs are **stopped / deallocated**.
- The **DR** `hp-avd-westus` host pool is **ready to accept connections** — it has at least one session host with **`AllowNewSession = true`**.

Use `Update-AzWvdSessionHost -AllowNewSession:$false` on the primary hosts (or `Stop-AzVM` on the primary session host VMs), and leave a `hp-avd-westus` session host enabled for new sessions. The validator confirms the primary is drained/stopped **and** that the DR pool has an available, session-accepting host.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.

<validation step="48199c95-8b6e-425b-b3e7-b4db2f428f80" />


**If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.**