<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	Cerner Corporation
	 Filename:     	VE_XD7StoreFrontWebReceiverCommunication.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontWebReceiverCommunication
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontWebReceiverCommunication.Resources.psd1;

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

        Write-Verbose "Calling Get-STFStoreService for $StoreName"
        $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
        Write-Verbose "Calling Get-STFWebReceiverService"
        $webreceiverservice = Get-STFWebReceiverService -StoreService $Storeservice
        Write-Verbose "Calling Get-STFWebReceiverCommunication"
        $Configuration = Get-STFWebReceiverCommunication -WebReceiverService $webreceiverservice
    }
    catch {

        Write-Verbose "Trapped error getting web receiver communication. Error: $($Error[0].Exception.Message)"
    }

    $returnValue = @{
        StoreName = [System.String]$StoreName
        Attempts = [System.UInt32]$configuration.Attempts
        Timeout = [System.String]$configuration.Timeout
        Loopback = [System.String]$configuration.Loopback
        LoopbackPortUsingHttp = [System.UInt32]$configuration.LoopbackPortUsingHttp
        ProxyEnabled = [System.Boolean]$configuration.Proxy.Enabled
        ProxyPort = [System.UInt32]$configuration.Proxy.Port
        ProxyProcessName = [System.String]$configuration.Proxy.ProcessName
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
        [System.UInt32]
        $Attempts,

        [Parameter()][System.String]
        $Timeout,

        [Parameter()]
        [ValidateSet('On','Off','OnUsingHttp')]
        [System.String]
        $Loopback,

        [Parameter()]
        [System.UInt32]
        $LoopbackPortUsingHttp,

        [Parameter()]
        [System.Boolean]
        $ProxyEnabled,

        [Parameter()]
        [System.UInt32]
        $ProxyPort,

        [Parameter()]
        [System.String]
        $ProxyProcessName
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
    $targetResource = Get-TargetResource @PSBoundParameters;
    foreach ($property in $PSBoundParameters.Keys) {
        if ($targetResource.ContainsKey($property)) {
            $expected = $PSBoundParameters[$property];
            $actual = $targetResource[$property];
            if ($PSBoundParameters[$property] -is [System.String[]]) {
                if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                    if (!($ChangedParams.ContainsKey($property))) {
                        Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                        $ChangedParams.Add($property,$PSBoundParameters[$property])
                    }
                }
            }
            elseif ($expected -ne $actual) {
                if (!($ChangedParams.ContainsKey($property))) {
                    Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                    $ChangedParams.Add($property,$PSBoundParameters[$property])
                }
            }
        }
    }

    $ChangedParams.Remove('StoreName')
    Write-Verbose -Message $localizedData.CallingSetSTFWebReceiverCommunication
    Set-STFWebReceiverCommunication @ChangedParams

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
        [System.UInt32]
        $Attempts,

        [Parameter()][System.String]
        $Timeout,

        [Parameter()]
        [ValidateSet('On','Off','OnUsingHttp')]
        [System.String]
        $Loopback,

        [Parameter()]
        [System.UInt32]
        $LoopbackPortUsingHttp,

        [Parameter()]
        [System.Boolean]
        $ProxyEnabled,

        [Parameter()]
        [System.UInt32]
        $ProxyPort,

        [Parameter()]
        [System.String]
        $ProxyProcessName
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
