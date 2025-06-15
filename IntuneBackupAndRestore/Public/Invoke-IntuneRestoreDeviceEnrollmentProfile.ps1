function Invoke-IntuneRestoreDeviceEnrollmentProfile {
    <#
    .SYNOPSIS
    Restore Intune iOS Device Enrollment Profiles
    
    .DESCRIPTION
    Restore Intune iOS Device Enrollment Profiles from JSON files per iOS Device Enrollment Profiles from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneRestoreDeviceEnrollmentProfile function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceEnrollmentProfile -Path "C:\temp" -RestoreById $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all App Protection Policies
    $enrollmentProfiles = Get-ChildItem -Path "$Path\Device Enrollment Profiles" -File -ErrorAction SilentlyContinue
    $DepOnboardingSettings = Invoke-MgGraphRequest -OutputType PSObject -Uri "$ApiVersion/deviceManagement/depOnboardingSettings" | Get-MgGraphAllPages
    
    foreach ($enrollmentProfile in $enrollmentProfiles) {
        $enrollmentProfileContent = Get-Content -LiteralPath $enrollmentProfile.FullName | ConvertFrom-Json
        $enrollmentProfileDisplayName = $enrollmentProfileContent.displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $enrollmentProfileContent

        $requestBodyObject.PSObject.Properties | ForEach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version | ConvertTo-Json -Depth 100

        # Restore the iOS Device Enrollment Profiles
        try {
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri "$ApiVersion/deviceManagement/depOnboardingSettings/$($DepOnboardingSettings.id)/enrollmentProfiles" -ErrorAction Stop

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "iOS Device Enrollment Profiles"
                "Name"   = $enrollmentProfileDisplayName
                #"Path"   = "App Protection Policies\$($enrollmentProfile.Name)"
            }
        } catch {
            Write-Verbose "$enrollmentProfileDisplayName - Failed to restore iOS Device Enrollment Profiles" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
