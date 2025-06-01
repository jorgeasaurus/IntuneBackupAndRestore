function Invoke-IntuneBackupConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune Settings Catalog Policy Assignments
    
    .DESCRIPTION
    Backup Intune Settings Catalog Policy Assignments as JSON files per Settings Catalog Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupConfigurationPolicyAssignment -Path "C:\temp"
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
    $configurationPolicies = (Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/configurationPolicies").value

    if ($configurationPolicies.value -ne "") {

        Write-Output "Backup - [Settings Catalog Assignments]"

        # Create folder if not exists
        if (-not (Test-Path "$Path\Settings Catalog\Assignments")) {
            $null = New-Item -Path "$Path\Settings Catalog\Assignments" -ItemType Directory
        }
	
        $Output = foreach ($configurationPolicy in $configurationPolicies) {
            $assignments = (Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/configurationPolicies/$($configurationPolicy.id)/assignments").value
            if ($assignments) {
                $fileName = ($configurationPolicy.name) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
                $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Settings Catalog\Assignments\$fileName.json"
	
            }
            [PSCustomObject]@{
                configurationPolicy = $configurationPolicy | Select-Object name,createdDateTime,lastModifiedDateTime,platforms,id
                Assignments         = @($assignments)
            }
        }
        $jsonfilename = "configurationPolicies.json"
        $outputPathFile = Join-Path  $path $jsonfilename
        $Output | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputPathFile -Encoding UTF8
    }
}