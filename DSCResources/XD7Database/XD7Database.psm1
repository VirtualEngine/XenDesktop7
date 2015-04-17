<#
function Create-DB {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [String] $DBUSER,
        #[Parameter(Mandatory)] [ValidateNotNullOrEmpty()] $DBPWD,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] $Database_CredObject,
        [Parameter()] [ValidateNotNullOrEmpty()] [String] $DBSERVER
        
    )

    process {

            #$DBPWD = $DBPWD | ConvertTo-SecureString -asPlainText -Force
            #$Database_CredObject = New-Object System.Management.Automation.PSCredential($DBUSER,$DBPWD)

            Write-Verbose ('Starting DB Creation at ' + (get-date).ToLongTimeString());
            $Sresult = New-XDDatabase -AdminAddress $env:COMPUTERNAME -SiteName $defaults.SITENAME -DataStore Site -DatabaseServer $DBSERVER -DatabaseName $defaults.DBSITENAME -DatabaseCredentials $Database_CredObject 
            Write-Verbose ('Created Site DB ' + $Sresult.Name + ' on '+ $Sresult.ServerAddress + ' at ' + (get-date).ToLongTimeString());

            $Lresult = New-XDDatabase -AdminAddress $env:COMPUTERNAME -SiteName $defaults.SITENAME -DataStore Logging -DatabaseServer $DBSERVER  -DatabaseName $defaults.DBLOGNAME -DatabaseCredentials $Database_CredObject 
            Write-Verbose ('Created Loging DB ' + $Lresult.Name + ' on '+ $Lresult.ServerAddress + ' at ' + (get-date).ToLongTimeString());

            $Mresult = New-XDDatabase -AdminAddress $env:COMPUTERNAME -SiteName $defaults.SITENAME -DataStore Monitor -DatabaseServer $DBSERVER  -DatabaseName $defaults.DBMONNAME -DatabaseCredentials $Database_CredObject
            Write-Verbose ('Created Monitor DB ' + $Mresult.Name + ' on '+ $Mresult.ServerAddress + ' at ' + (get-date).ToLongTimeString());
            Write-Verbose ('Finished DB Creation at ' + (get-date).ToLongTimeString());

    }
}
#>