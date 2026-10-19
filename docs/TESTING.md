# Testing

Each scenario can be repeated for a live demonstration. Sample events for the function's Test/Run screen are described in the project documentation (Appendix B). Screenshots are in [screenshots/](screenshots/) and in the PDF.

| ID | Scenario | Action | Expected result |
|---|---|---|---|
| T1 | Untagged resource | Create a storage account with no tags in the resource group | `Department = IT` appears within about a minute; `AutoRemediated` record |
| T2 | Already tagged resource | Send the event for a tagged resource | No change |
| T3 | Virtual machine | Send the VM event | Approval email arrives; `ApprovalRequested` record |
| T4 | Approve | Click Approve in the email | "Remediation APPROVED" email; Logic App Condition = true |
| T5 | Reject | Click Reject in a new email | "Remediation REJECTED" email; False branch green |
| T6 | Dry run | Set mode `dryrun`, create a public IP | `WouldDelete` record; the IP remains |
| T7 | Keep tag | Create a public IP with `Keep = true` | `DeleteSkipped` record; the IP remains |
| T8 | Automatic delete | Set mode `on`, create a public IP | IP deleted; `AutoDeleted` record |
| T9 | Outside scope | Create a resource in another resource group | Ignored by the system |
| T10 | Failure alert | Send an event for a non-existent storage account | Alert email arrives |
| T11 | Audit trail | Open Cosmos DB Items | Records for T1 to T8 present |
| T12 | Key Vault reference | Check the `LOGICAPP_URL` setting | Reference resolved; approval email still sent |
| T13 | Dashboard | Open the web app | Records and totals displayed |

## Notes on the audit data

Some audit records have status `Failed`. They come from events on child resources that cannot carry tags (for example resource locks, role definitions and `tags/default`) and from the deliberate failure test in T10. They are recorded honestly rather than hidden. Ignoring non-taggable resource types is listed under future work.
