Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $LoggingDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $MonitorDatabaseName
    )
    begin {
        if (-not (TestModule -Name 'Citrix.XenDesktop.Admin')) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        try {
            ## ErrorAction is ignored :@
            $xdSite = Get-XDSite -ErrorAction SilentlyContinue;
        }
        catch {
            
        }
        $targetResource = @{
            SiteName = $xdSite.Name;
            DatabaseServer = $DatabaseServer;
            SiteDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Site | Select-Object -ExpandProperty Name;
            LoggingDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Logging | Select-Object -ExpandProperty Name;
            MonitorDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Monitor | Select-Object -ExpandProperty Name;
        }
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $LoggingDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $MonitorDatabaseName
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($targetResource.SiteName -ne $SiteName) { return $true; }
        elseif ($targetResource.SiteDatabaseName -ne $SiteDatabaseName) { return $true; }
        elseif ($targetResource.LoggingDatabaseName -ne $LoggingDatabaseName) { return $true; }
        elseif ($targetResource.MonitorDatabaseName -ne $MonitorDatabaseName) { return $true; }
        else { return $false; }
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $LoggingDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $MonitorDatabaseName
    )
    begin {
        if (-not (TestModule -Name 'Citrix.XenDesktop.Admin')) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        $newXDSiteParams = @{
            SiteName = $SiteName;
            DatabaseServer = $DatabaseServer;
            SiteDatabaseName = $SiteDatabaseName;
            LoggingDatabaseName = $LoggingDatabaseName;
            MonitorDatabaseName = $MonitorDatabaseName;
        }
        Write-Verbose ($localizedData.CreatingXDSite -f $DataStore, $DatabaseName, $DatabaseServer);
        $xdSite = New-XDSite @newXDSiteParams;
    } #end process
} #end function Test-TargetResource
