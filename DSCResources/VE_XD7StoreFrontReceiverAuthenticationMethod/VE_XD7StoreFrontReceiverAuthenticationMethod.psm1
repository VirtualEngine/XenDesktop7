Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontReceiverAuthenticationMethod.Resources.psd1;

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
        [System.UInt16] $SiteId = 1
    )
    begin {

        AssertXDModule -Name 'WebReceiverModule','StoresModule','UtilsModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management";

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

                try { Write-Verbose -Message $message }
                catch { }
            }
        }

        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management";
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;
        Import-Module (FindXDModule -Name 'WebReceiverModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;
        Import-Module (FindXDModule -Name 'StoresModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;

        $authenticationMethods = Get-DSWebReceiverAuthenticationMethods -SiteId $SiteId -VirtualPath $VirtualPath;

        $targetResource = @{
            VirtualPath = $VirtualPath;
            SiteId = $SiteId;
            AuthenticationMethod = $AuthenticationMethods;
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
        [System.UInt16] $SiteId = 1
    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;

        $inDesiredState = $true;

        ## Check we have the specified methods
        foreach ($method in $AuthenticationMethod) {

            if ($targetResource.AuthenticationMethod -notcontains $method) {
                Write-Verbose -Message ($localizedData.ResourcePropertyMismatch -f 'AuthenticationMethod', $method, '<Null>');
                $inDesiredState = $false;
            }
        }

        ## Check whether other methods are present
        foreach ($method in $targetResource.AuthenticationMethod) {

            if ($AuthenticationMethod -notcontains $method) {
                Write-Verbose -Message ($localizedData.ResourcePropertyMismatch -f 'AuthenticationMethod', '<Null>', $method);
                $inDesiredState = $false;
            }
        }

        if ($inDesiredState) {

            Write-Verbose ($localizedData.ResourceInDesiredState -f $BaseUrl);
            return $true;
        }
        else {

            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $BaseUrl);
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
        [System.UInt16] $SiteId = 1
    )
    begin {

        AssertXDModule -Name 'WebReceiverModule','StoresModule','UtilsModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management";

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

                try { Write-Verbose -Message $message }
                catch { }
            }
        }

        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management";
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;
        Import-Module (FindXDModule -Name 'WebReceiverModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;
        Import-Module (FindXDModule -Name 'StoresModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false;

        Write-Verbose ($localizedData.UpdatingReceiverAuthenticationService -f $VirtualPath);
        [ref] $null = Set-DSWebReceiverAuthenticationMethods -SiteId $SiteId -VirtualPath $VirtualPath -AuthenticationMethods $AuthenticationMethod;

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
