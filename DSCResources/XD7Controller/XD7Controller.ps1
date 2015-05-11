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
            Import-Module 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1';
            try {
                ## ErrorAction is ignored :@
                $xdSite = Get-XDSite -AdminAddress $AdminAddress -ErrorAction Stop;
                $xdCustomSite = [PSCustomObject] @{
                    SiteName = $xdSite.Name;
                    Controllers = $xdSite | Select-Object -ExpandProperty Controllers;
                }
                return $xdCustomSite;
            }
            catch {
                Write-Error $_;
            }
        } #end scriptBlock

        $invokeCommandParams = @{
            ComputerName = $env:COMPUTERNAME;
            Credential = $Credential;
            Authentication = 'Credssp';
            ScriptBlock = $scriptBlock;
            ArgumentList = @($ExistingControllerName);
            ErrorAction = 'SilentlyContinue';
        }
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
        if ($xdSite.SiteName -eq $SiteName -and $xdSite.Ensure -eq $Ensure) {
            return $true;
        }
        return $false;
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
                [System.String] $ExistingControllerName,
                [System.String] $Ensure,
                [System.Management.Automation.PSCredential] $Credential
            )
            Import-Module 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1';
            Remove-Variable -Name CitrxHLSSdkContext -Force; ##
            if ($Ensure -eq 'Present') {
                $addXDControllerParams = @{
                    AdminAddress = $ExistingControllerName;
                    SiteControllerAddress = $AdminAddress;
                }
                if ($Credential) {
                    $addXDControllerParams['DatabaseCredentials'] = $Credential;
                }
                Add-XDController @addXDControllerParams -ErrorAction Stop;
            }
            else {
                $removeXDControllerParams = @{
                    AdminAddress = $AdminAddress;
                    ControllerName = $ExistingControllerName;
                }
                if ($Credential) {
                    $removeXDControllerParams['DatabaseCredentials'] = $Credential;
                }
                Remove-XDController @removeXDControllerParams -ErrorAction Stop;
            }
        };
        $localHostName = GetHostName;
        $invokeCommandParams = @{
            ComputerName = $env:COMPUTERNAME;
            Credential = $Credential;
            Authentication = 'Credssp';
            ScriptBlock = $scriptBlock;
            ArgumentList = @($ExistingControllerName, $localHostName, $Ensure, $Credential);
            ErrorAction = 'SilentlyContinue';
        }
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
