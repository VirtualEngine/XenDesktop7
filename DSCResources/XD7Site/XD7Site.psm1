<#
function Create-Site {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [String] $LicenseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [String] $DBserver,
        [Parameter(Mandatory)] [ValidateSet('PLT', 'ENT', 'APP', 'STD')] $LicenseServer_ProductEdition

        
    )

    process {

            $LicenseServerUri = 'https://'+$LicenseServer+':8083/'

            Write-Verbose ('Starting Site Creation at ' + (get-date).ToLongTimeString());
            $NSresult = New-XDSite -AdminAddress $env:COMPUTERNAME -SiteName $defaults.SITENAME -DatabaseServer $DBserver -LoggingDatabaseName $defaults.DBLOGNAME -MonitorDatabaseName $defaults.DBMONNAME -SiteDatabaseName $defaults.DBSITENAME 
            Write-Verbose ('Finished Creating Site at ' + (get-date).ToLongTimeString());

            Write-Verbose ('Starting Site Configuration at ' + (get-date).ToLongTimeString());
            $XDLresult = Set-XDLicensing -AdminAddress $env:COMPUTERNAME -LicenseServerAddress $LicenseServer -LicenseServerPort 27000 | Out-Null
            $CSresult = Set-ConfigSite  -AdminAddress $env:COMPUTERNAME -LicenseServerName $LicenseServer -LicenseServerUri $LicenseServerUri -LicenseServerPort $defaults.LICPORT -LicensingModel $defaults.LICMODEL -ProductCode $defaults.LICPRDCODE -ProductEdition $LicenseServer_ProductEdition | out-null
            $CSMresult = Set-ConfigSiteMetadata -AdminAddress $env:COMPUTERNAME -Name 'CertificateHash' -Value $(Get-LicCertificate -AdminAddress "https://$LicenseServer").CertHash | Out-Null
            Write-Verbose ('Finished Site Configuration at ' + (get-date).ToLongTimeString());

    }
}

function Join-Site {
    [CmdletBinding()]
    param (
        # Framework version to check against.
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Controller

    )

    process {
        
        Write-Verbose ('Attempting to Join Site using ' + $Controller + ' at ' + (get-date).ToLongTimeString());
        Add-XDController -AdminAddress $env:COMPUTERNAME -SiteControllerAddress $Controller
        Write-Verbose ('Joined Site at ' + (get-date).ToLongTimeString());
   }
 }
#>