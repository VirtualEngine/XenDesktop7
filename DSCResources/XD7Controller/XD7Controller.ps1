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
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        $scriptBlock = {
            $VerbosePreference = 'SilentlyContinue';
            Import-Module "$env:ProgramFiles\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1";
            $VerbosePreference = 'Continue';

            $xdSite = Get-XDSite -AdminAddress $using:AdminAddress -ErrorAction Stop;
            $xdCustomSite = [PSCustomObject] @{
                SiteName = $xdSite.Name;
                Controllers = $xdSite | Select-Object -ExpandProperty Controllers;
            }
            return $xdCustomSite;
        } #end scriptBlock
        
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        ## Overwrite the local ComputerName returned by AddInvokeScriptBlockCredentials
        $invokeCommandParams['ComputerName'] = $ExistingControllerName;
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($ExistingControllerName)));
        $xdSite = Invoke-Command @invokeCommandParams;
        $targetResource = @{
            SiteName = $xdSite.SiteName;
            ControllerName = $ExistingControllerName;
            Credential = $Credential;
            Ensure = 'Absent';
        }
        $localHostName = GetHostName;
        if ($xdSite.Controllers.DnsName -contains $localHostName) {
            Write-Verbose ($localizedData.ControllerDoesExist -f $localHostName, $xdSite.SiteName);
            $targetResource['Ensure'] = 'Present';
        }
        else {
            Write-Verbose ($localizedData.ControllerDoesNotExist -f $localHostName, $xdSite.SiteName);
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
            $VerbosePreference = 'SilentlyContinue';
            Import-Module "$env:ProgramFiles\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1";
            Remove-Variable -Name CitrxHLSSdkContext -Force -ErrorAction SilentlyContinue;
            $VerbosePreference = 'Continue';
            
            if ($using:Ensure -eq 'Present') {
                $addXDControllerParams = @{
                    AdminAddress = $using:ControllerName;
                    SiteControllerAddress = $using:AdminAddress;
                }
                Write-Verbose ($using:localizedData.AddingXDController -f $localHostName, $using:SiteName);
                Add-XDController @addXDControllerParams -ErrorAction Stop;
            }
            else {
                $removeXDControllerParams = @{
                    ControllerName = $using:ExistingControllerName;
                }
                Write-Verbose ($using:localizedData.RemovingXDController -f $using:localHostName, $using:SiteName);
                Remove-XDController @removeXDControllerParams -ErrorAction Stop;
            }
        } #end scriptBlock
        
        $localHostName = (GetHostName);
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        ## Override the local computer name returned by AddInvokeScriptBlockCredentials with
        ## the existing XenDesktop controller address
        $invokeCommandParams['ComputerName'] = $ExistingControllerName;
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($ExistingControllerName, $localHostName, $Ensure, $Credential)));
        Invoke-Command @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
