[CloudLabs Validator](https://spektra-systems.visualstudio.com/CloudLabs-Validator)

Lab Code: AVDDR

> Validations for this assessment query **Azure resources directly** via the `Az` and
> `Az.DesktopVirtualization` PowerShell cmdlets (the tasks create AVD / Storage / Compute
> resources in the lab subscription / resource group, not in-VM state), scoped to the lab
> resource group. They require the lab identity to hold the relevant **AVD / Contributor**
> roles and a **licensed, AVD-enabled** environment. Each task maps to a script in this folder,
> keyed by its `<validation step="…"/>` UUID. Every validator retries up to 3 times
> (`Start-Sleep -Seconds 10`), always returns HTTP `OK`, and carries the pass/fail in the JSON
> `Status` field (`Succeeded`/`Failed`). The FSLogix in-session-host registry configuration in
> Exercise 3 is verified by inspection; the validator confirms the geo-redundant storage half.

| Task | Validation step UUID | Script |
|---|---|---|
| Exercise 1 / Task 1 — Deploy the DR host pool hp-avd-westus with a registered session host | ffdbeaae-7635-457d-823b-e1185d61360b | validate-task1-dr-hostpool.ps1 |
| Exercise 2 / Task 1 — Register hp-avd-westus with the existing ws-avd workspace | 0924e6eb-ca78-43af-8b42-7aa6a20a563a | validate-task2-register-workspace.ps1 |
| Exercise 3 / Task 1 — FSLogix on the profiles share + geo-redundant storage | 99533b66-374d-4015-8ff8-a70a29fa70cb | validate-task3-fslogix-replication.ps1 |
| Exercise 4 / Task 1 — Simulate a regional outage and confirm DR continuity | 635c7a09-2797-4e59-be7e-4c950fe06de7 | validate-task4-outage-continuity.ps1 |
