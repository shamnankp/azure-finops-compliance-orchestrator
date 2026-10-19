# Troubleshooting log

Problems met during the build, their causes and the fixes.

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 1 | Tags page shows "Failed to fetch tags from ARG" and no results | Portal display error, not a missing tag | Check the Overview page or run `Get-AzTag` in Cloud Shell |
| 2 | Test/Run returns 202 Accepted but the tag is not applied | The function failed silently because Application Insights was off | Turn on Application Insights and read the log or Invocations page |
| 3 | Log shows "The term Get-AzTag is not recognized" | The Az module was not loaded; the Az line in `requirements.psd1` was commented out | Enable `Az.Accounts` and `Az.Resources`, save, restart, and wait for the first run to download modules |
| 4 | Test/Run succeeds in under a second and prints nothing | The Body box was empty | Paste a test event into the Body before clicking Run |
| 5 | Approval email is in Spam | New automated sender | Click "Not spam" once |
| 6 | Role removal failed: scope is locked | A lock existed on the resource group | Remove the resource-group lock and place locks on individual resources instead |
| 7 | Cannot create a secret in Key Vault | The vault uses RBAC and the administrator had no data-plane role | Assign Key Vault Secrets Officer to the administrator |
| 8 | Logic App URL appeared outside Azure | A URL containing its secret key was shared | Regenerate the Logic App access key and update the Key Vault secret |
| 9 | A mistyped `AUTO_DELETE_MODE` could have enabled deletion | The original condition only checked for "not equal to off" | The condition now requires the exact values `dryrun` or `on` |
| 10 | A fake public IP event no longer sends an approval email | In `dryrun` or `on` mode public IPs follow the delete path | Use the virtual machine event for the approval demonstration |
