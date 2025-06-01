function Invoke-IntuneRestoreAutopilotDeploymentProfileAssignment {
    <#
    .SYNOPSIS
    Restore Intune Autopilot Deployment Profile Assignments
    
    .DESCRIPTION
    Restore Intune Autopilot Deployment Profile Assignments from JSON files per profile from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAutopilotDeploymentProfileAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Autopilot Deployment Profiles that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Autopilot Deployment Profiles that match the file name.
    This is necessary if the Autopilot Deployment Profile was restored from backup, because then a new Autopilot Deployment Profile is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceHealthScriptAssignment -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Get all profiles with assignments
    $winAutopilotDeploymentProfiles = Get-ChildItem -Path "$Path\Autopilot Deployment Profiles\Assignments" -File -ErrorAction SilentlyContinue


    foreach ($profileFile in $winAutopilotDeploymentProfiles) {
        $assignments = Get-Content -LiteralPath $profileFile.FullName | ConvertFrom-Json
        # Extract the Autopilot profile ID (before the first “:”)
        $profileId = ($assignments[0]).id.Split("_")[0]

        # Retrieve the Autopilot Deployment Profile object (by ID or by name)
        try {
            if ($restoreById) {
                $profileObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$profileId"
            } else {
                $allProfiles = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles" | Get-MgGraphAllPages
                $profileObject = $allProfiles | Where-Object displayName -EQ $profileFile.BaseName
                if (-not $profileObject) {
                    Write-Verbose "Profile '$($profileFile.BaseName)' not found in Intune; skipping assignment restore." -Verbose
                    continue
                }
            }
        } catch {
            Write-Verbose "Error retrieving Autopilot profile for '$($profileFile.Name)'; skipping." -Verbose
            continue
        }

        $assignUrlBase = "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$($profileObject.id)/assignments"

        foreach ($entry in $assignments) {
            $targetObject = $entry.target

            # Build a JSON payload for exactly one assignment
            $singlePayload = @{
                "target" = $targetObject
            } | ConvertTo-Json -Depth 10

            try {
                $null = Invoke-MgGraphRequest `
                    -Method POST `
                    -Uri $assignUrlBase `
                    -Body $singlePayload `
                    -ContentType "application/json" `
                    -ErrorAction Stop

                [PSCustomObject]@{
                    Action = "Restore"
                    Type   = "Autopilot Deployment Profile Assignment"
                    Name   = $profileObject.displayName
                    Group  = if ($targetObject.groupId) { $targetObject.groupId } else { "All Devices" }
                }
            } catch {
                Write-Verbose "Failed to restore assignment for group $($targetObject.groupId) under profile '$($profileObject.displayName)'." -Verbose
                Write-Error $_
                continue
            }
        }
    }
}