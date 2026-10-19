# Limitations and future work

## Current limitations

- The rule set is small. The system implements three working rules (Department tag, public IP handling, virtual machine approval) to prove the design. Rules for public storage access and disk encryption are not built.
- Approving a request sends a confirmation email and records the decision. It does not yet execute a remediation action.
- Automatic deletion is limited to public IP addresses. Virtual machines always need approval.
- The Function App uses the classic Consumption plan on Windows, which does not support virtual network integration. The private endpoints described in the original proposal are not implemented.
- Resources are spread over several regions (South India, Central US, West US 2) because of regional availability on the subscription.
- One resource creation can emit several write events, so more than one audit record may appear for it.
- Approvals use email through the Outlook.com connector, not Microsoft Teams.
- Benchmark findings from Azure Policy (CIS) and Defender for Cloud are reported but not fixed automatically. The CIS audit on the project resource group shows many non-compliant policies, which form the backlog for future rules.
- The custom policy that denies virtual machines in South Africa North is assigned to the resource group. Its blocking behaviour has not been recorded as a test.
- The audit log does not record who created a resource. The dashboard shows the 100 most recent records.

## Future work

- Execute a real remediation (for example stop or delete) when an administrator clicks Approve.
- Add more rules: public blob access on storage accounts, unencrypted disks, a mandatory Environment tag.
- Use an `ExpiresOn` tag with a daily timer function that asks for approval before deleting expired resources.
- Add a scheduled scan that reports orphaned disks, network interfaces and public IPs.
- Package the deployment as Bicep templates with a CI/CD pipeline.
- Move to Flex Consumption with VNet integration and private endpoints for Cosmos DB and Key Vault.
- Send approvals to Microsoft Teams and add monthly cost reports.
- Record the caller identity in the audit log, label auto-fixed resources as "Unassigned", and add a Microsoft Entra ID login to the dashboard.
