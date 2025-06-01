function Invoke-IntuneBackupDeviceConfigurationAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Configuration Assignments
    
    .DESCRIPTION
    Backup Intune Device Configuration Assignments as JSON files per Device Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceConfigurationAssignment -Path "C:\temp"
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

    # Get all assignments from all policies
    $deviceConfigurations = Invoke-MgGraphRequest -Uri "$apiVersion/deviceManagement/deviceConfigurations" | Get-MGGraphAllPages

    if ($deviceConfigurations.value -ne "") {

        Write-Output "Backup - [Device Configuration Assignments]"

        # Create folder if not exists
        if (-not (Test-Path "$Path\Device Configurations\Assignments")) {
            $null = New-Item -Path "$Path\Device Configurations\Assignments" -ItemType Directory
        }
	
        $Output = foreach ($deviceConfiguration in $deviceConfigurations) {
            $assignments = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceConfigurations/$($deviceConfiguration.id)/assignments" | Get-MGGraphAllPages
	
            if ($assignments) {
                $fileName = ($deviceConfiguration.displayName) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
                $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Configurations\Assignments\$fileName.json"
            }
            [PSCustomObject]@{
                deviceConfiguration = $deviceConfiguration | Select-Object id,displayName,"@odata.type",createdDateTime,lastModifiedDateTime
                Assignments         = @($assignments)
            }
        }
        $jsonfilename = "deviceConfiguration.json"
        $outputPathFile = Join-Path  $path $jsonfilename
        $Output | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputPathFile -Encoding UTF8
    }
}
