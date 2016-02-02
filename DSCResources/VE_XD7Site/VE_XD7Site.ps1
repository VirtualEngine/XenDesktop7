Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SiteDatabaseName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $LoggingDatabaseName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $MonitorDatabaseName,
        
        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        $scriptBlock = {
            Import-Module "$env:ProgramFiles\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1" -Verbose:$false;
            try {
                $xdSite = Get-XDSite;
            }
            catch { }
            $targetResource = @{
                SiteName = $xdSite.Name;
                DatabaseServer = $xdSite.Databases | Where-Object Datastore -eq Site | Select-Object -ExpandProperty ServerAddress;
                SiteDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Site | Select-Object -ExpandProperty Name;
                LoggingDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Logging | Select-Object -ExpandProperty Name;
                MonitorDatabaseName = $xdSite.Databases | Where-Object Datastore -eq Monitor | Select-Object -ExpandProperty Name;
            };
            return $targetResource;
        };

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose $localizedData.InvokingScriptBlock;
        return Invoke-Command @invokeCommandParams;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SiteDatabaseName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $LoggingDatabaseName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $MonitorDatabaseName,
        
        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        $inCompliance = $true;
        if ($targetResource.SiteName -ne $SiteName) { $inCompliance = $false; }
        elseif ($targetResource.SiteDatabaseName -ne $SiteDatabaseName) { $inCompliance = $false; }
        elseif ($targetResource.LoggingDatabaseName -ne $LoggingDatabaseName) { $inCompliance = $false; }
        elseif ($targetResource.MonitorDatabaseName -ne $MonitorDatabaseName) { $inCompliance = $false; }
        if ($inCompliance) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $SiteName);
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $SiteName);
        }
        return $inCompliance;
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SiteDatabaseName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $LoggingDatabaseName,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $MonitorDatabaseName,
        
        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        $scriptBlock = {
            Import-Module "$env:ProgramFiles\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1" -Verbose:$false;

            $newXDSiteParams = @{
                SiteName = $using:SiteName;
                DatabaseServer = $using:DatabaseServer;
                SiteDatabaseName = $using:SiteDatabaseName;
                LoggingDatabaseName = $using:LoggingDatabaseName;
                MonitorDatabaseName = $using:MonitorDatabaseName;
            }
            $xdSite = New-XDSite @newXDSiteParams;
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($SiteName, $DatabaseServer, $SiteDatabaseName, $LoggingDatabaseName, $MonitorDatabaseName)));
        Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Test-TargetResource
