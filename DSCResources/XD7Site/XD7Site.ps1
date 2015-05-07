Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $LoggingDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $MonitorDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        $scriptBlock = {
            Import-Module 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1';
            try {
                ## ErrorAction is ignored :@
                $xdSite = Get-XDSite;
                $xdCustomSite = [PSCustomObject] @{
                    SiteName = $xdSite.Name;
                    DatabaseServer = $xdSite.Databases | Where-Object Datastore -eq Site | Select-Object -ExpandProperty ServerAddress;
                    SiteDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Site | Select-Object -ExpandProperty Name;
                    LoggingDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Logging | Select-Object -ExpandProperty Name;
                    MonitorDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Monitor | Select-Object -ExpandProperty Name;
                };
                return $xdCustomSite;
            }
            catch {
                Write-Error $_;
            }
        };
        $invokeCommandParams = @{
            ComputerName = $env:COMPUTERNAME;
            Credential = $Credential;
            Authentication = 'Credssp';
            ScriptBlock = $scriptBlock;
            ErrorAction = 'SilentlyContinue';
        }
        Write-Verbose $localizedData.InvokingScriptBlock;
        $targetResource = Invoke-Command @invokeCommandParams;
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
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $MonitorDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($targetResource.SiteName -ne $SiteName) { return $false; }
        elseif ($targetResource.SiteDatabaseName -ne $SiteDatabaseName) { return $false; }
        elseif ($targetResource.LoggingDatabaseName -ne $LoggingDatabaseName) { return $false; }
        elseif ($targetResource.MonitorDatabaseName -ne $MonitorDatabaseName) { return $false; }
        return $true;
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $LoggingDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $MonitorDatabaseName,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        $scriptBlock = {
            param (
                [System.String] $SiteName,
                [System.String] $DatabaseServer,
                [System.String] $SiteDatabaseName,
                [System.String] $LoggingDatabaseName,
                [System.String] $MonitorDatabaseName
            )
            try {
                Import-Module 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1';
                $newXDSiteParams = @{
                    SiteName = $SiteName;
                    DatabaseServer = $DatabaseServer;
                    SiteDatabaseName = $SiteDatabaseName;
                    LoggingDatabaseName = $LoggingDatabaseName;
                    MonitorDatabaseName = $MonitorDatabaseName;
                }
                $xdSite = New-XDSite @newXDSiteParams -ErrorAction SilentlyContinue;
            }
            catch {
                Write-Error $_;
            }
        } #end scriptBLock
        $invokeCommandParams = @{
            ComputerName = $env:COMPUTERNAME;
            Credential = $Credential;
            Authentication = 'Credssp';
            ScriptBlock = $scriptBlock;
            ArgumentList = @($SiteName, $DatabaseServer, $SiteDatabaseName, $LoggingDatabaseName, $MonitorDatabaseName);
            ErrorAction = 'Stop';
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        $invokeCommandResult = Invoke-Command @invokeCommandParams;
    } #end process
} #end function Test-TargetResource
