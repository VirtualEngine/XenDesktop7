<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	Cerner Corporation
	 Filename:     	VE_XD7StoreFrontWebReceiverPluginAssistant.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontWebReceiverPluginAssistant
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontWebReceiverPluginAssistant.Resources.psd1;

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

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {

        Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
        Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverService
        $webreceiverservice = Get-STFWebReceiverService -StoreService $Storeservice
        Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverPluginAssistant
        $Configuration = Get-STFWebReceiverPluginAssistant -WebReceiverService $webreceiverservice
    }
    catch {

        Write-Verbose -Message ($localizedData.TrappedError -f $Error[0].Exception.Message)
    }

    $returnValue = @{
        StoreName = [System.String]$StoreName
        Enabled = [System.Boolean]$Configuration.Enabled
        UpgradeAtLogin = [System.Boolean]$Configuration.UpgradeAtLogin
        ShowAfterLogin = [System.Boolean]$Configuration.ShowAfterLogin
        Win32Path = [System.String]$Configuration.Win32.Path
        MacOSPath = [System.String]$Configuration.MacOS.Path
        MacOSMinimumSupportedVersion = [System.String]$Configuration.MacOS.MinimumSupportedVersion
        Html5Enabled = [System.String]$Configuration.Html5.Enabled
        Html5Platforms = [System.String]$Configuration.html5.Platforms
        Html5Preferences = [System.String]$Configuration.html5.Preferences
        Html5SingleTabLaunch = [System.Boolean]$Configuration.html5.SingleTabLaunch
        Html5ChromeAppOrigins = [System.String]$Configuration.html5.ChromeAppOrigins
        Html5ChromeAppPreferences = [System.String]$Configuration.html5.ChromeAppPreferences
        ProtocolHandlerEnabled = [System.Boolean]$Configuration.ProtocolHandler.Enabled
        ProtocolHandlerPlatforms = [System.String]$Configuration.ProtocolHandler.Platforms
        ProtocolHandlerSkipDoubleHopCheckWhenDisabled = [System.Boolean]$Configuration.ProtocolHandler.SkipDoubleHopCheckWhenDisabled
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $UpgradeAtLogin,

        [Parameter()]
        [System.Boolean]
        $ShowAfterLogin,

        [Parameter()]
        [System.String]
        $Win32Path,

        [Parameter()]
        [System.String]
        $MacOSPath,

        [Parameter()]
        [System.String]
        $MacOSMinimumSupportedVersion,

        [Parameter()]
        [ValidateSet('Always','Fallback','Off')]
        [System.String]
        $Html5Enabled,

        [Parameter()]
        [System.String]
        $Html5Platforms,

        [Parameter()]
        [System.String]
        $Html5Preferences,

        [Parameter()]
        [System.Boolean]
        $Html5SingleTabLaunch,

        [Parameter()]
        [System.String]
        $Html5ChromeAppOrigins,

        [Parameter()]
        [System.String]
        $Html5ChromeAppPreferences,

        [Parameter()]
        [System.Boolean]
        $ProtocolHandlerEnabled,

        [Parameter()]
        [System.String]
        $ProtocolHandlerPlatforms,

        [Parameter()]
        [System.Boolean]
        $ProtocolHandlerSkipDoubleHopCheckWhenDisabled
    )

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {
        Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
        Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverService
        $webreceiverservice = Get-STFWebReceiverService -StoreService $Storeservice
    }
    catch {

        Write-Verbose -Message ($localizedData.TrappedError -f $Error[0].Exception.Message)
    }

    $ChangedParams = @{
        webreceiverservice = $webreceiverservice
    }
    $targetResource = Get-TargetResource -StoreName $StoreName
    foreach ($property in $PSBoundParameters.Keys) {
        if ($targetResource.ContainsKey($property)) {
            $expected = $PSBoundParameters[$property];
            $actual = $targetResource[$property];
            if ($PSBoundParameters[$property] -is [System.String[]]) {
                if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                    if (!($ChangedParams.ContainsKey($property))) {
                        Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                        $ChangedParams.Add($property, $PSBoundParameters[$property])
                    }
                }
            }
            elseif ($expected -ne $actual) {
                if (!($ChangedParams.ContainsKey($property))) {
                    Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                    $ChangedParams.Add($property, $PSBoundParameters[$property])
                }
            }
        }
    }

    $ChangedParams.Remove('StoreName')
    Write-Verbose -Message $localizedData.CallingSetSTFWebReceiverPluginAssistant
    Set-STFWebReceiverPluginAssistant @ChangedParams

}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $UpgradeAtLogin,

        [Parameter()]
        [System.Boolean]
        $ShowAfterLogin,

        [Parameter()]
        [System.String]
        $Win32Path,

        [Parameter()]
        [System.String]
        $MacOSPath,

        [Parameter()]
        [System.String]
        $MacOSMinimumSupportedVersion,

        [Parameter()]
        [ValidateSet('Always','Fallback','Off')]
        [System.String]
        $Html5Enabled,

        [Parameter()]
        [System.String]
        $Html5Platforms,

        [Parameter()]
        [System.String]
        $Html5Preferences,

        [Parameter()]
        [System.Boolean]
        $Html5SingleTabLaunch,

        [Parameter()]
        [System.String]
        $Html5ChromeAppOrigins,

        [Parameter()]
        [System.String]
        $Html5ChromeAppPreferences,

        [Parameter()]
        [System.Boolean]
        $ProtocolHandlerEnabled,

        [Parameter()]
        [System.String]
        $ProtocolHandlerPlatforms,

        [Parameter()]
        [System.Boolean]
        $ProtocolHandlerSkipDoubleHopCheckWhenDisabled
    )

    $targetResource = Get-TargetResource -StoreName $StoreName
    $inCompliance = $true;
    foreach ($property in $PSBoundParameters.Keys) {
        if ($targetResource.ContainsKey($property)) {
            $expected = $PSBoundParameters[$property];
            $actual = $targetResource[$property];
            if ($PSBoundParameters[$property] -is [System.String[]]) {
                if ($actual) {
                    if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual -ErrorAction silentlycontinue) {
                        Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, ($expected -join ','), ($actual -join ','));
                        $inCompliance = $false;
                    }
                }
                else {
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

