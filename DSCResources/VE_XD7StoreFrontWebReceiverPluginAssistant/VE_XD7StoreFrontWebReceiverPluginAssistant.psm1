function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [System.Boolean]
        $Enabled,

        [System.Boolean]
        $UpgradeAtLogin,

        [System.Boolean]
        $ShowAfterLogin,

        [System.String]
        $Win32Path,

        [System.String]
        $MacOSPath,

        [System.String]
        $MacOSMinimumSupportedVersion,

        [ValidateSet("Always","Fallback","Off")]
        [System.String]
        $Html5Enabled,

        [System.String]
        $Html5Platforms,

        [System.String]
        $Html5Preferences,

        [System.Boolean]
        $Html5SingleTabLaunch,

        [System.String]
        $Html5ChromeAppOrigins,

        [System.String]
        $Html5ChromeAppPreferences,

        [System.Boolean]
        $ProtocolHandlerEnabled,

        [System.String]
        $ProtocolHandlerPlatforms,

        [System.Boolean]
        $ProtocolHandlerSkipDoubleHopCheckWhenDisabled
    )

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {
        Write-Verbose "Calling Get-STFStoreService for $StoreName"
        $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
        Write-Verbose "Calling Get-STFWebReceiverService"
        $webreceiverservice = Get-STFWebReceiverService -StoreService $Storeservice
        Write-Verbose "Calling Get-STFWebReceiverPluginAssistant"
        $Configuration = Get-STFWebReceiverPluginAssistant -WebReceiverService $webreceiverservice
    }
    catch {
        Write-Verbose "Trapped error getting web receiver plugin configuration. Error: $($Error[0].Exception.Message)"
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
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [System.Boolean]
        $Enabled,

        [System.Boolean]
        $UpgradeAtLogin,

        [System.Boolean]
        $ShowAfterLogin,

        [System.String]
        $Win32Path,

        [System.String]
        $MacOSPath,

        [System.String]
        $MacOSMinimumSupportedVersion,

        [ValidateSet("Always","Fallback","Off")]
        [System.String]
        $Html5Enabled,

        [System.String]
        $Html5Platforms,

        [System.String]
        $Html5Preferences,

        [System.Boolean]
        $Html5SingleTabLaunch,

        [System.String]
        $Html5ChromeAppOrigins,

        [System.String]
        $Html5ChromeAppPreferences,

        [System.Boolean]
        $ProtocolHandlerEnabled,

        [System.String]
        $ProtocolHandlerPlatforms,

        [System.Boolean]
        $ProtocolHandlerSkipDoubleHopCheckWhenDisabled
    )

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {
        Write-Verbose "Calling Get-STFStoreService for $StoreName"
        $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
        Write-Verbose "Calling Get-STFWebReceiverService"
        $webreceiverservice = Get-STFWebReceiverService -StoreService $Storeservice
        Write-Verbose "Calling Get-STFWebReceiverPluginAssistant"
        $Configuration = Get-STFWebReceiverPluginAssistant -WebReceiverService $webreceiverservice
    }
    catch {
        Write-Verbose "Trapped error getting web receiver plugin configuration. Error: $($Error[0].Exception.Message)"
    }

    $ChangedParams = @{
        webreceiverservice = $webreceiverservice
    }
    $targetResource = Get-TargetResource @PSBoundParameters;
    foreach ($property in $PSBoundParameters.Keys) {
        if ($targetResource.ContainsKey($property)) {
            $expected = $PSBoundParameters[$property];
            $actual = $targetResource[$property];
            if ($PSBoundParameters[$property] -is [System.String[]]) {
                if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                    if (!($ChangedParams.ContainsKey($property))) {
                        Write-Verbose "Adding $property to ChangedParams"
                        $ChangedParams.Add($property,$PSBoundParameters[$property])
                    }
                }
            }
            elseif ($expected -ne $actual) {
                if (!($ChangedParams.ContainsKey($property))) {
                    Write-Verbose "Adding $property to ChangedParams"
                    $ChangedParams.Add($property,$PSBoundParameters[$property])
                }
            }
        }
    }

    $ChangedParams.Remove('StoreName')
    Write-Verbose "Calling Set-STFWebReceiverPluginAssistant"
    Set-STFWebReceiverPluginAssistant @ChangedParams

}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [System.Boolean]
        $Enabled,

        [System.Boolean]
        $UpgradeAtLogin,

        [System.Boolean]
        $ShowAfterLogin,

        [System.String]
        $Win32Path,

        [System.String]
        $MacOSPath,

        [System.String]
        $MacOSMinimumSupportedVersion,

        [ValidateSet("Always","Fallback","Off")]
        [System.String]
        $Html5Enabled,

        [System.String]
        $Html5Platforms,

        [System.String]
        $Html5Preferences,

        [System.Boolean]
        $Html5SingleTabLaunch,

        [System.String]
        $Html5ChromeAppOrigins,

        [System.String]
        $Html5ChromeAppPreferences,

        [System.Boolean]
        $ProtocolHandlerEnabled,

        [System.String]
        $ProtocolHandlerPlatforms,

        [System.Boolean]
        $ProtocolHandlerSkipDoubleHopCheckWhenDisabled
    )

    $targetResource = Get-TargetResource @PSBoundParameters;
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

