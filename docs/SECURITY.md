# Security design

## What is in place

- **No stored credentials.** The function and the dashboard use managed identities. The only secret, the Logic App URL, is kept in Key Vault and referenced from settings.
- **Least privilege.** The function holds Tag Contributor, a custom role that can only read and delete public IP addresses, a Cosmos DB data role and Key Vault Secrets User. The broad Contributor role used during testing was removed. The dashboard identity can only read Cosmos DB data.
- **Scope guard.** The code ignores everything outside the project resource group.
- **Human approval** for virtual machines, and for public IPs when automatic delete is off.
- **Protection against accidents:** delete locks, the `Keep` tag, dry-run mode and a kill switch (`AUTO_DELETE_MODE`).
- **Network exposure:** the dashboard accepts traffic only from the administrator's IP address.
- **Audit trail and alerts:** every action is recorded in Cosmos DB, and failures raise an Azure Monitor alert.
- **Policy auditing:** Azure Policy (tag standard, CIS benchmark in audit mode) and Defender for Cloud report on compliance.

## Known gaps

- **Auto-tagging is a governance control, not a security control.** It does not block or inspect anything. A resource created by an attacker would simply be labelled `Department = IT`. Real protection comes from least-privilege access, multi-factor authentication and Azure Policy deny rules.
- **The audit record does not store who created the resource.** The Activity Log has the caller's identity; recording it in Cosmos DB is future work.
- **The dashboard IP restriction cannot tell people on the same network apart.** Anyone behind the allowed public IP can open it. A login with Microsoft Entra ID is future work.
- **The function's custom role** is limited to public IP deletion, but any added permission (for example storage updates) can only be granted at resource-type level, not per property.

## Secrets and this repository

No keys, connection strings or trigger URLs are stored in this repository. Settings are read from environment variables at run time.
