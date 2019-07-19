<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	Cerner Corporation
	 Filename:     	VE_XD7StoreFrontWebReceiverUserInterface.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontWebReceiverUserInterface
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontWebReceiverUserInterface.Resources.psd1;

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
        Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverUserInterface
        $Configuration = Get-STFWebReceiverUserInterface -WebReceiverService $webreceiverservice
    }
    catch {

        Write-Verbose -Message ($localizedData.TrappedError -f $Error[0].Exception.Message)
    }

    $returnValue = @{
        StoreName = [System.String]$StoreName
        AutoLaunchDesktop = [System.Boolean]$Configuration.AutoLaunchDesktop
        MultiClickTimeout = [System.UInt32]$Configuration.MultiClickTimeout
        EnableAppsFolderView = [System.Boolean]$Configuration.EnableAppsFolderView
        ShowAppsView = [System.Boolean]$Configuration.UIViews.ShowAppsView
        ShowDesktopsView = [System.Boolean]$Configuration.UIViews.ShowDesktopsView
        DefaultView = [System.String]$Configuration.UIViews.DefaultView
        WorkspaceControlEnabled = [System.Boolean]$Configuration.WorkspaceControl.Enabled
        WorkspaceControlAutoReconnectAtLogon = [System.Boolean]$Configuration.WorkspaceControl.AutoReconnectAtLogon
        WorkspaceControlLogoffAction = [System.String]$Configuration.WorkspaceControl.LogoffAction
        WorkspaceControlShowReconnectButton = [System.Boolean]$Configuration.WorkspaceControl.ShowReconnectButton
        WorkspaceControlShowDisconnectButton = [System.Boolean]$Configuration.WorkspaceControl.ShowDisconnectButton
        ReceiverConfigurationEnabled = [System.Boolean]$Configuration.ReceiverConfiguration.Enabled
        AppShortcutsEnabled = [System.Boolean]$Configuration.AppShortcuts.Enabled
        AppShortcutsAllowSessionReconnect = [System.Boolean]$Configuration.AppShortcuts.AllowSessionReconnect
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
        $AutoLaunchDesktop,

        [Parameter()]
        [System.UInt32]
        $MultiClickTimeout,

        [Parameter()]
        [System.Boolean]
        $EnableAppsFolderView,

        [Parameter()]
        [System.Boolean]
        $ShowAppsView,

        [Parameter()]
        [System.Boolean]
        $ShowDesktopsView,

        [Parameter()]
        [ValidateSet('Apps','Auto','Desktops')]
        [System.String]
        $DefaultView,

        [Parameter()]
        [System.Boolean]
        $WorkspaceControlEnabled,

        [Parameter()]
        [System.Boolean]
        $WorkspaceControlAutoReconnectAtLogon,

        [Parameter()]
        [ValidateSet('Disconnect','None','Terminate')]
        [System.String]
        $WorkspaceControlLogoffAction,

        [Parameter()]
        [System.Boolean]
        $WorkspaceControlShowReconnectButton,

        [Parameter()]
        [System.Boolean]
        $WorkspaceControlShowDisconnectButton,

        [Parameter()]
        [System.Boolean]
        $ReceiverConfigurationEnabled,

        [Parameter()]
        [System.Boolean]
        $AppShortcutsEnabled,

        [Parameter()]
        [System.Boolean]
        $AppShortcutsAllowSessionReconnect
    )

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {

        Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
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
    Write-Verbose -Message $localizedData.CallingSetSTFWebReceiverUserInterface
    Set-STFWebReceiverUserInterface @ChangedParams

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
        $AutoLaunchDesktop,

        [Parameter()]
        [System.UInt32]
        $MultiClickTimeout,

        [Parameter()]
        [System.Boolean]
        $EnableAppsFolderView,

        [Parameter()]
        [System.Boolean]
        $ShowAppsView,

        [Parameter()]
        [System.Boolean]
        $ShowDesktopsView,

        [Parameter()]
        [ValidateSet('Apps','Auto','Desktops')]
        [System.String]
        $DefaultView,

        [Parameter()]
        [System.Boolean]
        $WorkspaceControlEnabled,

        [Parameter()]
        [System.Boolean]
        $WorkspaceControlAutoReconnectAtLogon,

        [Parameter()]
        [ValidateSet('Disconnect','None','Terminate')]
        [System.String]
        $WorkspaceControlLogoffAction,

        [Parameter()]
        [System.Boolean]
        $WorkspaceControlShowReconnectButton,

        [Parameter()]
        [System.Boolean]
        $WorkspaceControlShowDisconnectButton,

        [Parameter()]
        [System.Boolean]
        $ReceiverConfigurationEnabled,

        [Parameter()]
        [System.Boolean]
        $AppShortcutsEnabled,

        [Parameter()]
        [System.Boolean]
        $AppShortcutsAllowSessionReconnect
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
