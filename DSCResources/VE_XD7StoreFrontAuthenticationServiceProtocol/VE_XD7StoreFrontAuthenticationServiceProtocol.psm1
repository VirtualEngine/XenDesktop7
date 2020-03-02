Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontAuthenticationServiceProtocol.Resources.psd1;

function Get-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## Citrix Storefront Authentication Service IIS Virtual Path
        [Parameter(Mandatory)]
        [System.String] $VirtualPath,

        ## Explicit authentication methods available
        [Parameter(Mandatory)]
        [ValidateSet('IntegratedWindows','HttpBasic','ExplicitForms','CitrixFederation','CitrixAGBasic','Certificate','CitrixAGBasicNoPassword','Forms-Saml')]
        [System.String[]] $AuthenticationProtocol,

        ## Citrix Storefront Authentication Service IIS Site Id
        [Parameter()]
        [System.UInt64] $SiteId = 1,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    begin
    {
        AssertModule -Name Citrix.StoreFront.Authentication
    }
    process
    {
        Import-Module Citrix.StoreFront.Authentication -ErrorAction Stop -Verbose:$false;
        $authenticationService = Get-STFAuthenticationService -VirtualPath $VirtualPath -SiteId $SiteId
        $authenticationProtocols = Get-STFAuthenticationServiceProtocol -AuthenticationService $authenticationService

        $targetResource = @{
            VirtualPath = $VirtualPath;
            SiteId = $SiteId;
            AuthenticationProtocol = $authenticationProtocols | Where-Object { $_.Enabled -eq $true } | Select-Object -ExpandProperty Name
            Ensure = if ($null -ne $authenticationService) { 'Present' } else { 'Absent' }
        }

        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        ## Citrix Storefront Authentication Service IIS Virtual Path
        [Parameter(Mandatory)]
        [System.String] $VirtualPath,

        ## Explicit authentication methods available
        [Parameter(Mandatory)]
        [ValidateSet('IntegratedWindows','HttpBasic','ExplicitForms','CitrixFederation','CitrixAGBasic','Certificate','CitrixAGBasicNoPassword','Forms-Saml')]
        [System.String[]] $AuthenticationProtocol,

        ## Citrix Storefront Authentication Service IIS Site Id
        [Parameter()]
        [System.UInt64] $SiteId = 1,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    process
    {
        $targetResource = Get-TargetResource @PSBoundParameters;
        $inDesiredState = $true;

        foreach ($protocol in $AuthenticationProtocol)
        {
            if ($Ensure -eq 'Present') {

                if ($targetResource.AuthenticationProtocol -notcontains $protocol)
                {
                    Write-Verbose -Message ($localizedData.ResourcePropertyMismatch -f 'AuthenticationProtocol', $protocol, '<Null>');
                    $inDesiredState = $false;
                }
            }
            elseif ($Ensure -eq 'Absent')
            {
                if ($targetResource.AuthenticationProtocol -contains $protocol)
                {
                    Write-Verbose -Message ($localizedData.ResourcePropertyMismatch -f 'AuthenticationProtocol', '<Null>', $protocol);
                    $inDesiredState = $false;
                }
            }
        }

        if ($inDesiredState)
        {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $VirtualPath);
            return $true;
        }
        else
        {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $VirtualPath);
            return $false;
        }

    } #end process
} #end function Test-TargetResource


function Set-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        ## Citrix Storefront Authentication Service IIS Virtual Path
        [Parameter(Mandatory)]
        [System.String] $VirtualPath,

        ## Explicit authentication methods available
        [Parameter(Mandatory)]
        [ValidateSet('IntegratedWindows','HttpBasic','ExplicitForms','CitrixFederation','CitrixAGBasic','Certificate','CitrixAGBasicNoPassword','Forms-Saml')]
        [System.String[]] $AuthenticationProtocol,

        ## Citrix Storefront Authentication Service IIS Site Id
        [Parameter()]
        [System.UInt16] $SiteId = 1,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    begin
    {
        AssertModule -Name Citrix.StoreFront.Authentication
    }
    process
    {
        Import-Module Citrix.StoreFront.Authentication -ErrorAction Stop -Verbose:$false;
        $authenticationService = Get-STFAuthenticationService -VirtualPath $VirtualPath -SiteId $SiteId

        Write-Verbose ($localizedData.UpdatingAuthenticationService -f $VirtualPath);

        if ($Ensure -eq 'Present')
        {
            Write-Verbose ($localizedData.EnablingAuthenticationProtocol -f ($AuthenticationProtocol -join ', '))
            Enable-STFAuthenticationServiceProtocol -Name $AuthenticationProtocol -AuthenticationService $authenticationService
        }
        elseif ($Ensure -eq 'Absent')
        {
            Write-Verbose ($localizedData.DisablingAuthenticationProtocol -f ($AuthenticationProtocol -join ', '))
            Disable-STFAuthenticationServiceProtocol -Name $AuthenticationProtocol -AuthenticationService $authenticationService
        }

    } #end process
} #end function Set-TargetResource


## Import the XD7Common library functions
$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
