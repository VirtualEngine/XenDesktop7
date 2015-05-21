Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $ExistingControllerName, ## Existing controller used to join/remove the site.
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential, ## Database credentials used to join/remove the controller to/from the site.
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
    )
    begin {
        if (-not (TestXDModule)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        $scriptBlock = {
            param (
                [System.String] $AdminAddress
            )
            $VerbosePreference = 'SilentlyContinue';
            Import-Module 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1';
            $xdSite = Get-XDSite -AdminAddress $AdminAddress -ErrorAction Stop;
            $xdCustomSite = [PSCustomObject] @{
                SiteName = $xdSite.Name;
                Controllers = $xdSite | Select-Object -ExpandProperty Controllers;
            }
            return $xdCustomSite;
        } #end scriptBlock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($ExistingControllerName);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        ## Overwrite the local ComputerName returned by AddInvokeScriptBlockCredentials
        $invokeCommandParams['ComputerName'] = $ExistingControllerName;
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        $xdSite = Invoke-Command @invokeCommandParams;
        $targetResource = @{
            SiteName = $xdSite.SiteName;
            ControllerName = $ExistingControllerName;
            Credential = $Credential;
            Ensure = 'Absent';
        }
        $localHostName = GetHostName;
        if ($xdSite.Controllers.DnsName -contains $localHostName) {
            Write-Verbose ($localizedData.XDControllerDoesExist -f $localHostName, $xdSite.SiteName);
            $targetResource['Ensure'] = 'Present';
        }
        else {
            Write-Verbose ($localizedData.XDControllerDoesNotExist -f $localHostName, $xdSite.SiteName);
        }
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $ExistingControllerName, ## Existing controller used to join/remove the site
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential, ## Database credentials used to join/remove the controller to/from the site.
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
    )
    process {
        $xdSite = Get-TargetResource @PSBoundParameters;
        $localHostName = GetHostName;
        if ($xdSite.SiteName -eq $SiteName -and $xdSite.Ensure -eq $Ensure) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $localHostName);
            return $true;
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $localHostName);
            return $false;
        }
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $ExistingControllerName, ## Existing controller used to join the site
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential, ## Database credentials used to join/remove the controller to/from the site.
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
    )
    begin {
        if (-not (TestXDModule)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        $scriptBlock = {
            param (
                [System.String] $AdminAddress,
                [System.String] $ControllerName,
                [System.String] $Ensure,
                [System.Management.Automation.PSCredential] $Credential
            )
            $VerbosePreference = 'SilentlyContinue';
            Import-Module 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1';
            Remove-Variable -Name CitrxHLSSdkContext -Force -ErrorAction SilentlyContinue; ##
            if ($Ensure -eq 'Present') {
                $addXDControllerParams = @{
                    AdminAddress = $ControllerName;
                    SiteControllerAddress = $AdminAddress;
                }
                if ($Credential) {
                    $addXDControllerParams['DatabaseCredentials'] = $Credential;
                }
                Add-XDController @addXDControllerParams -ErrorAction Stop;
            }
            else {
                $removeXDControllerParams = @{
                    ControllerName = $ExistingControllerName;
                }
                if ($Credential) {
                    $removeXDControllerParams['DatabaseCredentials'] = $Credential;
                }
                Remove-XDController @removeXDControllerParams -ErrorAction Stop;
            }
        };
        $localHostName = (GetHostName);
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($ExistingControllerName, $localHostName, $Ensure, $Credential);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        ## Override the local computer name returned by AddInvokeScriptBlockCredentials wiht
        ## the existing XenDesktop controller address
        $invokeCommandParams['ComputerName'] = $ExistingControllerName;
        if ($Ensure -eq 'Present') {
            Write-Verbose ($localizedData.AddingXDController -f $localHostName, $xdSite.SiteName);
        }
        else {
            Write-Verbose ($localizedData.RemovingXDController -f $localHostName, $xdSite.SiteName);
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        $invokeCommandResult = Invoke-Command @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
