param($eventGridEvent, $TriggerMetadata)

function Write-AuditLog {
    param($ResourceId, $Violation, $Action, $Status)
    try {
        $account = $env:COSMOS_ENDPOINT.TrimEnd('/')
        $uri = "$account/dbs/$($env:COSMOS_DB)/colls/$($env:COSMOS_CONTAINER)/docs"

        $token = (Get-AzAccessToken -ResourceUrl $account).Token
        if ($token -is [System.Security.SecureString]) {
            $token = [System.Net.NetworkCredential]::new('', $token).Password
        }

        $rg = if ($ResourceId -match "/resourceGroups/([^/]+)/") { $Matches[1] } else { "unknown" }

        $doc = @{
            id            = [guid]::NewGuid().ToString()
            resourceId    = $ResourceId
            resourceGroup = $rg
            violation     = $Violation
            action        = $Action
            status        = $Status
            timestamp     = (Get-Date).ToUniversalTime().ToString("o")
        } | ConvertTo-Json

        $headers = @{
            "Authorization"                = [uri]::EscapeDataString("type=aad&ver=1.0&sig=$token")
            "x-ms-date"                    = [DateTime]::UtcNow.ToString("r")
            "x-ms-version"                 = "2018-12-31"
            "x-ms-documentdb-partitionkey" = "[""$ResourceId""]"
        }

        Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $doc -ContentType "application/json" -SkipHeaderValidation -ErrorAction Stop | Out-Null
        "Audit record saved to Cosmos DB." | Out-Host
    }
    catch {
        Write-Warning "Audit log failed (main flow continues): $_"
    }
}

"Incoming Event Grid Payload:" | Out-Host
$eventGridEvent | Out-String | Out-Host

if ($eventGridEvent -is [string]) { $eventObject = $eventGridEvent | ConvertFrom-Json } else { $eventObject = $eventGridEvent }

$eventType = $eventObject.eventType
$data = $eventObject.data
if ($eventType -ne "Microsoft.Resources.ResourceWriteSuccess") { return }

$resourceId = $data.resourceUri
if (-not $resourceId) { $resourceId = $eventObject.subject }

if ($resourceId -notmatch "/resourceGroups/rg-finops-compliance-prod-Shamnan/providers/") {
    "Outside target scope, skipping: $resourceId" | Out-Host
    return
}
if ($resourceId -match "/providers/Microsoft.Resources/deployments/") {
    "Deployment event, skipping." | Out-Host
    return
}

# AUTOMATIC DELETE PATH (public IPs only; controlled by AUTO_DELETE_MODE: off | dryrun | on)
$mode = if ($env:AUTO_DELETE_MODE) { $env:AUTO_DELETE_MODE.ToLower() } else { "off" }

if ($resourceId -match "/providers/Microsoft.Network/publicIPAddresses/[^/]+$" -and ($mode -eq "dryrun" -or $mode -eq "on")) {
    try {
        $tags = $null
        try {
            $tags = (Get-AzTag -ResourceId $resourceId -ErrorAction Stop).Properties.TagsProperty
        }
        catch {
            if ("$_" -match "NotFound|could not be found|ResourceNotFound") {
                "Resource no longer exists, nothing to do." | Out-Host
                return
            }
            throw
        }

        if ($tags -and $tags.ContainsKey("Keep") -and $tags["Keep"] -eq "true") {
            "Keep=true tag present. Not deleting." | Out-Host
            Write-AuditLog -ResourceId $resourceId -Violation "Unapproved public IP" -Action "DeleteSkipped" -Status "KeepTag"
            return
        }

        if ($mode -eq "dryrun") {
            "DRY RUN: would delete $resourceId" | Out-Host
            Write-AuditLog -ResourceId $resourceId -Violation "Unapproved public IP" -Action "WouldDelete" -Status "DryRun"
            return
        }

        "Deleting public IP: $resourceId" | Out-Host
        $resp = Invoke-AzRestMethod -Method DELETE -Path "$($resourceId)?api-version=2023-09-01"

        if ($resp.StatusCode -eq 404) {
            "Already deleted, nothing to do." | Out-Host
            return
        }
        if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300) {
            "Deleted: $resourceId" | Out-Host
            Write-AuditLog -ResourceId $resourceId -Violation "Unapproved public IP" -Action "AutoDeleted" -Status "Success"
        }
        else {
            throw "Delete returned status $($resp.StatusCode): $($resp.Content)"
        }
    }
    catch {
        Write-AuditLog -ResourceId $resourceId -Violation "Unapproved public IP" -Action "AutoDeleted" -Status "Failed"
        Write-Error "Auto-delete failed: $_"
        throw
    }
    return
}

# HIGH-RISK PATH (VMs always; public IPs too when AUTO_DELETE_MODE is off)
if ($resourceId -match "/providers/Microsoft.(Network/publicIPAddresses|Compute/virtualMachines)/") {
    "High-risk resource detected. Requesting approval..." | Out-Host
    $body = @{
        resourceId     = $resourceId
        violation      = "High-risk resource created"
        proposedAction = "Review and approve"
        eventTime      = $eventObject.eventTime
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Method Post -Uri $env:LOGICAPP_URL -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        "Approval request sent to Logic App." | Out-Host
        Write-AuditLog -ResourceId $resourceId -Violation "High-risk resource created" -Action "ApprovalRequested" -Status "Pending"
    }
    catch {
        Write-AuditLog -ResourceId $resourceId -Violation "High-risk resource created" -Action "ApprovalRequested" -Status "Failed"
        Write-Error "Failed to call Logic App: $_"
        throw
    }
    return
}

"Processing resource: $resourceId" | Out-Host

# LOW-RISK PATH
try {
    $existingTags = (Get-AzTag -ResourceId $resourceId -ErrorAction Stop).Properties.TagsProperty
    if ($existingTags -and $existingTags.ContainsKey("Department")) {
        "Resource already complies with Department tag standards." | Out-Host
        return
    }
    "Department tag missing. Applying auto-remediation..." | Out-Host
    Update-AzTag -ResourceId $resourceId -Tag @{ Department = "IT" } -Operation Merge -ErrorAction Stop
    "Successfully remediated resource: $resourceId with Department: IT" | Out-Host
    Write-AuditLog -ResourceId $resourceId -Violation "MissingDepartmentTag" -Action "AutoRemediated" -Status "Success"
}
catch {
    Write-AuditLog -ResourceId $resourceId -Violation "MissingDepartmentTag" -Action "AutoRemediated" -Status "Failed"
    Write-Error "Failed to process resource remediation: $_"
    throw
}
