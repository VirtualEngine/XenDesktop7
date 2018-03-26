Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7WaitForSite.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ExistingControllerName,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()]
        [System.UInt64] $RetryIntervalSec = 30,

        [Parameter()]
        [System.UInt32] $RetryCount = 10
    )
    begin {

        if (-not (TestXDModule)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }

    } #end begin
    process {

        # No point testing availability here in Get-TargetResource!
        $targetResource = @{
            SiteName = $SiteName;
            ExistingControllerName = $ExistingControllerName;
            RetryIntervalSec = $RetryIntervalSec;
            RetryCount = $RetryCount;
        }

        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ExistingControllerName,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()]
        [System.UInt64] $RetryIntervalSec = 30,

        [Parameter()]
        [System.UInt32] $RetryCount = 10
    )
    process {

        Write-Verbose ($localizedData.TestingXDSite -f $SiteName, $ExistingControllerName);
        $xdSiteName = TestXDSite -ExistingControllerName $ExistingControllerName -Credential $Credential;

        if ($xdSiteName -eq $SiteName) {

            Write-Verbose ($localizedData.ResourceInDesiredState -f $SiteName);
            return $true;
        }
        else {

            if (-not ([System.String]::IsNullOrEmpty($xdSiteName))) {
                Write-Warning ($localizedData.IncorrectXDSiteNameWarning -f $xdSiteName);
            }

            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $SiteName);
            return $false;

        }
    } #end process

} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ExistingControllerName,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()]
        [System.UInt64] $RetryIntervalSec = 30,

        [Parameter()]
        [System.UInt32] $RetryCount = 10
    )
    process {

        for ($count = 0; $count -lt $RetryCount; $count++) {

            Write-Verbose ($localizedData.TestingXDSite -f $SiteName, $ExistingControllerName);
            $xdSiteName = TestXDSite -ExistingControllerName $ExistingControllerName -Credential $Credential;

            if ($xdSiteName -eq $SiteName) {
                break;
            }
            else {

                if (-not ([System.String]::IsNullOrEmpty($xdSiteName))) {
                    Write-Warning ($localizedData.IncorrectXDSiteNameWarning -f $xdSiteName);
                }
                Write-Verbose ($localizedData.XDSiteNotFoundRetrying -f $SiteName, $RetryIntervalSec);
                Start-Sleep -Seconds $RetryIntervalSec;
            }

        } #end foreach

        if (-not $xdSiteName) {
            ThrowOperationCanceledException -ErrorId 'OperationTimeout' -ErrorMessage ($localizedData.XDSiteNotFoundTimeout -f $SiteName, $RetryCount);
        }

    } #end process
} #end function Set-TargetResource


#region Private Functions

function TestXDSite {
<#
    .SYNOPSIS
        Checks whether the Citrix XenDesktop 7.x is available
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ExistingControllerName,

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    process {

        $scriptBlock = {

            $VerbosePreference = 'SilentlyContinue';
            Import-Module 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1';
            try {

                $xdSite = Get-XDSite -AdminAddress $using:ExistingControllerName -ErrorAction SilentlyContinue;
            }
            catch { } # Get-XDSite doesn't support $ErrorActionPreference :@

            return $xdSite.Name

        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        if ($null -ne $Credential) {

            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        else {

            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
        }

        Write-Verbose $localizedData.InvokingScriptBlock;

        return Invoke-Command @invokeCommandParams;

    } #end process
} #end function TestXDSite

#endregion Private Functions


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
