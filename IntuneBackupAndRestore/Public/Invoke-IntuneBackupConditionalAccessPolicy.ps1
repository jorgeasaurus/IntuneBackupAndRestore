function Invoke-IntuneBackupConditionalAccessPolicy {
    <#
    .SYNOPSIS
    Backup Intune Client Apps
    
    .DESCRIPTION
    Backup Intune Client Apps as JSON files per Conditiona lAccess Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupConditionalAccess -Path "C:\temp"
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
        Connect-MgGraph -Scopes "Policy.Read.All, DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all Client Apps
    $ConditionalAccessPolicies = Get-MgBetaIdentityConditionalAccessPolicy -All

    if ($ConditionalAccessPolicies.value -ne "") {


        Write-Output "Backup - [Conditional Access Policies] - Count [$($ConditionalAccessPolicies.count)]"

        # Create folder if not exists
        if (-not (Test-Path "$Path\Conditional Access Policies")) {
            $null = New-Item -Path "$Path\Conditional Access Policies" -ItemType Directory
        }
		
        foreach ($ConditionalAccessPolicy in $ConditionalAccessPolicies) {
	
            $fileName = ($ConditionalAccessPolicy.id) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
            $ConditionalAccessPolicy.ToJsonString() | Out-File -LiteralPath "$path\Conditional Access Policies\$fileName.json"
        }
    }
}