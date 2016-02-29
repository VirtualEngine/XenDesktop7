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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {
        AssertXDModule -Name 'Citrix.XenDesktop.Admin';
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
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        else {
            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
        }
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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
            $inCompliance = $true;
            foreach ($property in $PSBoundParameters.Keys) {
                if ($targetResource.ContainsKey($property)) {
                    $expected = $PSBoundParameters[$property];
                    $actual = $targetResource[$property];
                    if ($PSBoundParameters[$property] -is [System.String[]]) {
                        if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                            Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, ($expected -join ','), ($actual -join ','));
                            $inCompliance = $false;
                        }
                    }
                    elseif ($expected -ne $actual) {
                        Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, $expected, $actual);
                        $inCompliance = $false;
                    }
                }
            }
            if ($inCompliance) {
                Write-Verbose ($localizedData.ResourceInDesiredState -f $DeliveryGroup);
            }
            else {
                Write-Verbose ($localizedData.ResourceNotInDesiredState -f $DeliveryGroup);
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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {
        AssertXDModule -Name 'Citrix.XenDesktop.Admin';
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
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        else {
            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
        }
        $scriptBlockParams = @($SiteName, $DatabaseServer, $SiteDatabaseName, $LoggingDatabaseName, $MonitorDatabaseName);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Test-TargetResource
