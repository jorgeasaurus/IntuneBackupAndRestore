function Invoke-IntuneBackupDeviceEnrollmentProfile {
    <#
    .SYNOPSIS
    Backup Intune iOS Device Enrollment Profiles
    
    .DESCRIPTION
    Backup Intune iOS Device Enrollment Profiles as JSON files per profile to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceEnrollmentProfile -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Connect to Microsoft Graph if not already connected
    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All"
    }

    $DepOnboardingSettings = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/depOnboardingSettings" | Get-MgGraphAllPages

    if ($DepOnboardingSettings) {
    
        $enrollmentProfiles = foreach ($DepOnboardingSetting in $DepOnboardingSettings) {
            Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/depOnboardingSettings/$($DepOnboardingSetting.id)/enrollmentProfiles" | Get-MgGraphAllPages
        }
    }

    if ($enrollmentProfiles) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Device Enrollment Profiles")) {
            $null = New-Item -Path "$Path\Device Enrollment Profiles" -ItemType Directory
        }

        foreach ($profile in $enrollmentProfiles) {

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Enrollment Profile"
                "Name"   = $profile.displayName
                "Path"   = "Device Enrollment Profiles\$fileName.json"
            }

            # Filter for iOS-specific profiles (e.g., Device Enrollment Program or Apple Configurator)
            if ($profile.'@odata.type' -like "*ios*") {
                $fileName = ($profile.displayName) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
                $profile | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Device Enrollment Profiles\$fileName.json"
            }
        }
    }
}