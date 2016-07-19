Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontAuthenticationMethod.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## Citrix Storefront Authentication Service IIS Virtual Path
        [Parameter(Mandatory)]
        [System.String] $VirtualPath,

        ## Explicit authentication methods available
        [Parameter(Mandatory)]
        [ValidateSet('IntegratedWindows','HttpBasic','ExplicitForms','CitrixFederation','CitrixAGBasic','Certificate')]
        [System.String[]] $AuthenticationMethod,

        ## Citrix Storefront Authentication Service IIS Site Id
        [Parameter()]
        [System.UInt16] $SiteId = 1,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    begin {

        AssertXDModule -Name 'AuthenticationModule','UtilsModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management";

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
        Import-Module (FindXDModule -Name 'AuthenticationModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;

        $authenticationMethods = Get-DSWebReceiverAuthenticationMethods -SiteId $SiteId -VirtualPath $VirtualPath;

        $targetResource = @{
            VirtualPath = $VirtualPath;
            SiteId = $SiteId;
            AuthenticationMethod = $AuthenticationMethods;
            Ensure = if ($AuthenticationMethods) { 'Present' } else { 'Absent' }
        }
        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        ## Citrix Storefront Authentication Service IIS Virtual Path
        [Parameter(Mandatory)]
        [System.String] $VirtualPath,

        ## Explicit authentication methods available
        [Parameter(Mandatory)]
        [ValidateSet('IntegratedWindows','HttpBasic','ExplicitForms','CitrixFederation','CitrixAGBasic','Certificate')]
        [System.String[]] $AuthenticationMethod,

        ## Citrix Storefront Authentication Service IIS Site Id
        [Parameter()]
        [System.UInt16] $SiteId = 1,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;

        $inDesiredState = $true;
        foreach ($method in $AuthenticationMethod) {
            if ($Ensure -eq 'Present') {
                if ($targetResource.AuthenticationMethods -notcontains $method) {
                    Write-Verbose -Message ($localizedData.ResourcePropertyMismatch -f 'AuthenticationMethods', $method, '<Null>');
                    $inDesiredState = $false;
                }
            }
            elseif ($Ensure -eq 'Absent') {
                if ($targetResource.AuthenticationMethods -contains $method) {
                    Write-Verbose -Message ($localizedData.ResourcePropertyMismatch -f 'AuthenticationMethods', '<Null>', $method);
                    $inDesiredState = $false;
                }
            }
        }

        if ($inDesiredState) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $VirtualPath);
            return $true;
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $VirtualPath);
            return $false;
        }

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        ## Citrix Storefront Authentication Service IIS Virtual Path
        [Parameter(Mandatory)]
        [System.String] $VirtualPath,

        ## Explicit authentication methods available
        [Parameter(Mandatory)]
        [ValidateSet('IntegratedWindows','HttpBasic','ExplicitForms','CitrixFederation','CitrixAGBasic','Certificate')]
        [System.String[]] $AuthenticationMethod,

        ## Citrix Storefront Authentication Service IIS Site Id
        [Parameter()]
        [System.UInt16] $SiteId = 1,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    begin {

        AssertXDModule -Name 'WebReceiverModule','StoresModuleUtilsModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management";

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
        Import-Module (FindXDModule -Name 'AuthenticationModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;

        Write-Verbose ($localizedData.UpdatingAuthenticationService -f $VirtualPath);

        if ($Ensure -eq 'Present') {
            Write-Verbose ($localizedData.AddingAuthenticationMethod -f ($AuthenticationMethod -join ', '));
            Add-DSAuthenticationProtocolsDeployed -SiteId $SiteId -VirtualPath $VirtualPath -Protocols $AuthenticationMethod;
        }
        elseif ($Ensure -eq 'Absent') {
            Write-Verbose ($localizedData.RemovingAuthenticationMethod -f ($AuthenticationMethod -join ', '));
            Remove-DSAuthenticationProtocolsDeployed -SiteId $SiteId -VirtualPath $VirtualPath -Protocols $AuthenticationMethod;
        }

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
