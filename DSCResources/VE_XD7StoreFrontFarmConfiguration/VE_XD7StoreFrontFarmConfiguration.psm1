<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	Cerner Corporation
	 Filename:     	VE_XD7StoreFrontFarmConfiguration.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontFarmConfiguration
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontFarmConfiguration.Resources.psd1;

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

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false

    try {

        Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
        Write-Verbose -Message $localizedData.CallingGetSTFStoreFarmConfiguration
        ## This is a hack, as Get-STFStoreFarm throws an error if run twice in quick succession?!
        $null = Get-STFStoreFarm -StoreService $StoreService -Verbose -OutVariable Configuration
    }
    catch {

        Write-Verbose -Message ($localizedData.TrappedError -f $Error[0].Exception.Message)
    }

    $returnValue = @{
        StoreName = [System.String]$StoreName
        EnableFileTypeAssociation = [System.Boolean]$Configuration.EnableFileTypeAssociation
        CommunicationTimeout = [System.String]$Configuration.CommunicationTimeout
        ConnectionTimeout = [System.String]$Configuration.ConnectionTimeout
        LeasingStatusExpiryFailed = [System.String]$Configuration.LeasingStatusExpiryFailed
        LeasingStatusExpiryLeasing = [System.String]$Configuration.LeasingStatusExpiryLeasing
        LeasingStatusExpiryPending = [System.String]$Configuration.LeasingStatusExpiryPending
        #PooledSockets does not actually show up with the Get, so if you change this, it will always do the Set.
        PooledSockets = [System.Boolean]$Configuration.PooledSockets
        ServerCommunicationAttempts = [System.UInt32]$Configuration.ServerCommunicationAttempts
        BackgroundHealthCheckPollingPeriod = [System.String]$Configuration.BackgroundHealthCheckPollingPeriod
        AdvancedHealthCheck = [System.Boolean]$Configuration.AdvancedHealthCheck
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
        $EnableFileTypeAssociation,

        [Parameter()]
        [System.String]
        $CommunicationTimeout,

        [Parameter()]
        [System.String]
        $ConnectionTimeout,

        [Parameter()]
        [System.String]
        $LeasingStatusExpiryFailed,

        [Parameter()]
        [System.String]
        $LeasingStatusExpiryLeasing,

        [Parameter()]
        [System.String]
        $LeasingStatusExpiryPending,

        [Parameter()]
        [System.Boolean]
        $PooledSockets,

        [Parameter()]
        [System.UInt32]
        $ServerCommunicationAttempts,

        [Parameter()]
        [System.String]
        $BackgroundHealthCheckPollingPeriod,

        [Parameter()]
        [System.Boolean]
        $AdvancedHealthCheck
    )

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {

        Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
    }
    catch {

        Write-Verbose -Message ($localizedData.TrappedError -f $Error[0].Exception.Message)
    }

    $ChangedParams = @{
        StoreService = $StoreService
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
    Write-Verbose -Message $localizedData.CallingSetSTFStoreFarmConfiguration

    Set-STFStoreFarmConfiguration @ChangedParams

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
        $EnableFileTypeAssociation,

        [Parameter()]
        [System.String]
        $CommunicationTimeout,

        [Parameter()]
        [System.String]
        $ConnectionTimeout,

        [Parameter()]
        [System.String]
        $LeasingStatusExpiryFailed,

        [Parameter()]
        [System.String]
        $LeasingStatusExpiryLeasing,

        [Parameter()]
        [System.String]
        $LeasingStatusExpiryPending,

        [Parameter()]
        [System.Boolean]
        $PooledSockets,

        [Parameter()]
        [System.UInt32]
        $ServerCommunicationAttempts,

        [Parameter()]
        [System.String]
        $BackgroundHealthCheckPollingPeriod,

        [Parameter()]
        [System.Boolean]
        $AdvancedHealthCheck
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
