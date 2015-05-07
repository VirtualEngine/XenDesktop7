<#
function Add-Admins {
    param (
        # Framework version to check against.
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Administratorsgroup

    )

    process {

        Write-Verbose ('Adding Full Administrator Role for ' + $Administratorsgroup);
        New-AdminAdministrator  -AdminAddress $env:COMPUTERNAME -Enabled $True -Name $Administratorsgroup | Out-Null
        Add-AdminRight  -AdminAddress $env:COMPUTERNAME -Administrator $Administratorsgroup -Role 'Full Administrator' -Scope 'All'

    }
}
#>