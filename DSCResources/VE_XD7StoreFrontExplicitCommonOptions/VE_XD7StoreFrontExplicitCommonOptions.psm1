<#
    ===========================================================================
     Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
     Created on:   	2/8/2019 12:12 PM
     Created by:   	CERBDM
     Organization: 	Cerner Corporation
     Filename:     	VE_XD7StoreFrontExplicitCommonOptions.psm1
    -------------------------------------------------------------------------
     Module Name: VE_XD7StoreFrontExplicitCommonOptions
    ===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontExplicitCommonOptions.Resources.psd1;

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName
    )

    Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
    Write-Verbose -Message ($localized.CallingGetSTFStoreService -f $StoreName)
    $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
    Write-Verbose -Message ($localized.CallingGetSTFAuthenticationService)
    $Auth = Get-STFAuthenticationService -VirtualPath ($StoreService.AuthenticationServiceVirtualPath) -SiteID ($StoreService.SiteId)
    If ($Auth) {
        Write-Verbose -Message ($localized.CallingGetSTFExplicitCommonOptions -f $Auth.FriendlyName)
        $AuthOptions = Get-STFExplicitCommonOptions -AuthenticationService $Auth
    }

    #Getting default domain isn't in the regular output, have to jump through hoops here
    [xml]$WebConfig = Get-Content $Auth.ConfigurationFile
    $DefaultDomain = $WebConfig.configuration.'citrix.deliveryservices'.explicitBL.domainselection.default

    $returnValue = @{
        StoreName = $StoreName
        Domains = [System.String[]]$AuthOptions.DomainSelection
        DefaultDomain = [System.String]$DefaultDomain
        HideDomainField = [System.Boolean]$AuthOptions.HideDomainField
        AllowUserPasswordChange = [System.String]$AuthOptions.AllowUserPasswordChange
        ShowPasswordExpiryWarning = [System.String]$AuthOptions.ShowPasswordExpiryWarning
        PasswordExpiryWarningPeriod = [System.UInt32]$AuthOptions.PasswordExpiryWarningPeriod
        AllowZeroLengthPassword = [System.Boolean]$AuthOptions.AllowZeroLengthPassword
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter()]
        [System.String[]]
        $Domains,

        [Parameter()]
        [System.String]
        $DefaultDomain,

        [Parameter()]
        [System.Boolean]
        $HideDomainField,

        [Parameter()]
        [ValidateSet('Always','ExpiredOnly','Never')]
        [System.String]
        $AllowUserPasswordChange,

        [Parameter()]
        [ValidateSet('Custom','Never','Windows')]
        [System.String]
        $ShowPasswordExpiryWarning,

        [Parameter()]
        [System.UInt32]
        $PasswordExpiryWarningPeriod,

        [Parameter()]
        [System.Boolean]
        $AllowZeroLengthPassword
    )

    Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;
    Write-Verbose -Message ($localized.CallingGetSTFStoreService -f $StoreName)
    $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
    Write-Verbose -Message ($localized.CallingGetSTFAuthenticationService)
    $Auth = Get-STFAuthenticationService -VirtualPath $StoreService.AuthenticationServiceVirtualPath -SiteID $StoreService.SiteId

    $ChangedParams = @{
        AuthenticationService = $Auth
    }
    $targetResource = Get-TargetResource @PSBoundParameters;
    foreach ($property in $PSBoundParameters.Keys) {
        if ($targetResource.ContainsKey($property)) {
            $expected = $PSBoundParameters[$property];
            $actual = $targetResource[$property];
            if ($PSBoundParameters[$property] -is [System.String[]]) {
                if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                    if (!($ChangedParams.ContainsKey($property))) {
                        Write-Verbose -Message ($localized.SettingResourceProperty -f $property)
                        $ChangedParams.Add($property,$PSBoundParameters[$property])
                    }
                }
            }
            elseif ($expected -ne $actual) {
                if (!($ChangedParams.ContainsKey($property))) {
                    Write-Verbose -Message ($localized.SettingResourceProperty -f $property)
                    $ChangedParams.Add($property,$PSBoundParameters[$property])
                }
            }
        }
    }

    Write-Verbose -Message $localized.CallingSetSTFExplicitCommonOptions
    Set-STFExplicitCommonOptions @ChangedParams

}


function Test-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter()]
        [System.String[]]
        $Domains,

        [Parameter()]
        [System.String]
        $DefaultDomain,

        [Parameter()]
        [System.Boolean]
        $HideDomainField,

        [Parameter()]
        [ValidateSet('Always','ExpiredOnly','Never')]
        [System.String]
        $AllowUserPasswordChange,

        [Parameter()]
        [ValidateSet('Custom','Never','Windows')]
        [System.String]
        $ShowPasswordExpiryWarning,

        [Parameter()]
        [System.UInt32]
        $PasswordExpiryWarningPeriod,

        [Parameter()]
        [System.Boolean]
        $AllowZeroLengthPassword
    )

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

}


Export-ModuleMember -Function *-TargetResource
