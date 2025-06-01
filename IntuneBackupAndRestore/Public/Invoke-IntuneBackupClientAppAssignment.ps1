function Invoke-IntuneBackupClientAppAssignment {
    <#
    .SYNOPSIS
    Backup Intune Client App Assignments
    
    .DESCRIPTION
    Backup Intune Client App  Assignments as JSON files per Client App to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupClientAppAssignment -Path "C:\temp"
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

    # Get all Client Apps
    $filter = "microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true"
    $clientApps = Invoke-MgRestMethod -Uri "$apiversion/deviceAppManagement/mobileApps?filter=$filter" | Get-MgGraphAllPages

    if ($clientApps.value -ne "") {

        Write-Output "Backup - [Client Apps Assignments]"

        # Create folder if not exists
        if (-not (Test-Path "$Path\Client Apps\Assignments")) {
            $null = New-Item -Path "$Path\Client Apps\Assignments" -ItemType Directory
        }
	
        $Output = foreach ($clientApp in $clientApps) {
            $assignments = (Invoke-MgRestMethod -Uri "/$apiversion/deviceAppManagement/mobileApps/$($clientApp.id)/assignments").value
            if ($assignments) {
                $fileName = ($clientApp.displayName) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
                $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Client Apps\Assignments\$fileName.json"
            }
            [PSCustomObject]@{
                ClientApp   = $clientapp | Select-Object displayName,lastModifiedDateTime,isAssigned,notes,id,publisher,releaseDateTime,"@odata.type",applicableDeviceType,createdDateTime,totalLicenseCount,usedLicenseCount
                Assignments = @($assignments)
            }
           
        }
        $jsonfilename = "ClientApps.json"
        $outputPathFile = Join-Path  $path $jsonfilename
        $Output | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputPathFile -Encoding UTF8
    }
}