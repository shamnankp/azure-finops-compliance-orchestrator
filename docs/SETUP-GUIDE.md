# Setup guide: how the project was built

The full step-by-step guide with screenshots is in the project documentation PDF in this folder. This page is the short version.

## Build phases

| Phase | What was done |
|---|---|
| 1 | Resource group `rg-finops-compliance-prod-Shamnan` |
| 2 | Cosmos DB account (serverless), database `ComplianceDB`, container `AuditLogs` |
| 3 | Key Vault `vault-finops-shamnan` (Azure RBAC model) |
| 4 | Azure Policy assignment `Require-Department-Tag` (defines and reports the standard; the function corrects) |
| 5 | Function App `func-finops-orchestrator-shamnan` (PowerShell, Consumption) with Application Insights |
| 6 | Event Grid system topic `finops-system-topic` and subscription `sub-finops-remediation` |
| 7 | Managed identity and RBAC: Tag Contributor, custom public-IP role, Cosmos DB data roles, Key Vault Secrets User |
| 8 | Logic App `logic-finops-approval-shamnan` with Approve/Reject email |
| 9 | Logic App URL stored as a Key Vault secret and referenced from the function setting |
| 10 | Audit logging from the function to Cosmos DB |
| 11 | Function logic (`run.ps1`) |
| 12 | Optional automatic delete of public IPs with `AUTO_DELETE_MODE`, Keep tag and dry run |
| 13 | Azure Monitor alert rule `alert-finops-failed-remediation` and action group |
| 14 | Defender for Cloud (Foundational CSPM) |
| 15 | Container Instances group `aci-trivy-scan` running a Trivy image scan |
| 16 | Dashboard web app `app-finops-dashboard-shamnan` (Python 3.11, Free tier) restricted to the administrator IP |
| 17 | Delete locks (`protect-from-delete`) on key resources |

Additional Azure Policy work: a CIS Microsoft Azure Foundations Benchmark v2.0.0 assignment in audit-only mode on the resource group, and a custom policy that denies virtual machines in South Africa North (`infra/vm-rule.json`).

## Function settings

| Setting | Purpose |
|---|---|
| `COSMOS_ENDPOINT`, `COSMOS_DB`, `COSMOS_CONTAINER` | Where audit records are written |
| `LOGICAPP_URL` | Key Vault reference to the Logic App trigger URL (never stored in code) |
| `AUTO_DELETE_MODE` | `off`, `dryrun` or `on` |

## Resource inventory

| Resource | Type | Notes |
|---|---|---|
| rg-finops-compliance-prod-Shamnan | Resource group | South India |
| func-finops-orchestrator-shamnan | Function App | PowerShell, Consumption, Central US |
| stfinops99shamnan | Storage account | Function host storage |
| cosmos-finops-audit-shamnan | Cosmos DB for NoSQL | Serverless, West US 2 |
| vault-finops-shamnan | Key Vault | West US 2 |
| finops-system-topic | Event Grid system topic | Source: resource group |
| sub-finops-remediation | Event Grid subscription | Delivers to the function |
| logic-finops-approval-shamnan | Logic App (Consumption) | South India |
| plan-finops-dashboard | App Service plan | Free F1, South India |
| app-finops-dashboard-shamnan | Web App (Python) | Admin dashboard |
| alert-finops-failed-remediation | Monitor alert rule | Failed function runs |
| FinOpsAlert | Action group | Email notification |
| aci-trivy-scan | Container group | Run-once vulnerability scan |
| Public IP Deleter (FinOps) | Custom RBAC role | Read and delete public IPs only |

## Cost behaviour

All services are serverless or free tier, so idle cost is close to zero. Items to watch: Standard public IPs cost money while they exist (delete test IPs the same day), the log alert rule has a small monthly fee, and Container Instances bill only while running.

## Clean-up

1. Set `AUTO_DELETE_MODE` to `off`.
2. Delete test public IPs and the container group.
3. Regenerate the Logic App access key and update the Key Vault secret if the URL was ever shared.
4. Remove all resource locks first, otherwise the resource group cannot be deleted.
5. Delete the resource group to remove every resource at once.
