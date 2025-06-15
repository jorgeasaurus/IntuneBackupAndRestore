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
    $ConditionalAccessPolicies = Invoke-MgGraphRequest -OutputType PSObject -Uri "$ApiVersion/identity/conditionalAccess/policies" | Get-MgGraphAllPages

    if ($ConditionalAccessPolicies) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Conditional Access Policies")) {
            $null = New-Item -Path "$Path\Conditional Access Policies" -ItemType Directory
        }
		
        foreach ($ConditionalAccessPolicy in $ConditionalAccessPolicies) {
	
            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Conditional Access Policies"
                "Name"   = $ConditionalAccessPolicy.displayName
                "Path"   = "Conditional Access Policies\$fileName.json"
            }

            $fileName = ($ConditionalAccessPolicy.id) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
            $ConditionalAccessPolicy | ConvertTo-Json -Depth 5 | Out-File -LiteralPath "$path\Conditional Access Policies\$fileName.json"
        }
    }
}