Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontBaseUrl.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [System.String] $BaseUrl
    )
    begin {
        AssertXDModule -Name 'Citrix.DeliveryServices.Framework.Commands' -IsSnapin;
    }
    process {

        Add-PSSnapIn -Name 'Citrix.DeliveryServices.Framework.Commands' -ErrorAction Stop;
        $targetResource = @{
            BaseUrl = Get-DSFrameworkProperty -Key 'HostBaseUrl';
        }
        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [System.String] $BaseUrl
    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;
        if (-not $BaseUrl.EndsWith('/')) {
            $BaseUrl = '{0}/' -f $BaseUrl;
        }
        if ($BaseUrl -eq $targetResource.BaseUrl) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $BaseUrl);
            return $true;
        }
        else {
            Write-Verbose ($localizedData.ResourcePropertyMismatch -f 'BaseUrl', $BaseUrl, $targetResource.BaseUrl);
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $BaseUrl);
            return $false;
        }

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)]
        [System.String] $BaseUrl
    )
    begin {
        AssertXDModule -Name 'ClusterConfigurationModule','UtilsModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management";
    }
    process {

        function global:Write-Host {
            [CmdletBinding()]
            param (
                [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
                [System.Object] $Object,
                [System.Management.Automation.SwitchParameter] $NoNewLine,
                [System.ConsoleColor] $ForegroundColor,
                [System.ConsoleColor] $BackgroundColor
            )
            foreach ($message in $Object) {
                Write-Verbose $message;
            }
        }
        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management";
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;
        Import-Module (FindXDModule -Name 'ClusterConfigurationModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;
        Write-Verbose ($localizedData.UpdatingBaseUrl -f $BaseUrl);
        [ref] $null = Set-DSClusterAddress -NewHostBaseUrl $BaseUrl;

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
