<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	Cerner Corporation
	 Filename:     	VE_XD7StoreFrontWebReceiverService.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontWebReceiverService
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontWebReceiverService.Resources.psd1;

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VirtualPath
    )

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {

        Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
        Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverService
        $Configuration = Get-STFWebReceiverService -StoreService $StoreService
        [System.Xml.XmlDocument] $webConfig = Get-Content -Path $Configuration.ConfigurationFile -Raw
    }
    catch {

        Write-Verbose -Message ($localizedData.TrappedError -f $Error[0].Exception.Message)
    }

    $returnValue = @{
        StoreName = [System.String] $StoreName
        VirtualPath = [System.String] $Configuration.VirtualPath
        SiteId = [System.UInt64] $Configuration.SiteId
        ClassicReceiverExperience = [System.Boolean] $webConfig.Configuration.'system.webServer'.defaultDocument.files.add.value -notcontains 'recevier.html'
        SessionStateTimeout = [System.UInt32] $webConfig.Configuration.'system.web'.sessionState.Timeout
        DefaultIISSite = [System.Boolean] $Configuration.DefaultIISSite
        FriendlyName = [System.String] $Configuration.FriendlyName
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $VirtualPath,

        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter()]
        [System.Boolean]
        $ClassicReceiverExperience,

        [Parameter()]
        [System.String]
        $FriendlyName,

        [Parameter()]
        [System.UInt32]
        $SessionStateTimeout,

        [Parameter()]
        [System.Boolean]
        $DefaultIISSite,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {
        Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
        Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverService
        $Configuration = Get-STFWebReceiverService -StoreService $StoreService
    }
    catch {

        Write-Verbose -Message ($localizedData.TrappedError -f $Error[0].Exception.Message)
    }

    $ChangedParams = @{
        StoreService = $StoreService
        VirtualPath = $VirtualPath
        SiteId = $SiteId
    }
    $targetResource = Get-TargetResource -StoreName $StoreName -VirtualPath $VirtualPath
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
    $ChangedParams.Remove('DefaultIISSite')
    $ChangedParams.Remove('ClassicReceiverExperience')
    $ChangedParams.Remove('SessionStateTimeout')

    if ($Ensure -eq 'Present') {

        ## SessionStateTimeout and DefaultIISSite can only be configured with Set-STFWebReceiverStore
        if (-not $Configuration) {

            Write-Verbose -Message $localizedData.CallingAddSTFWebReceiverService
            $Configuration = Add-STFWebReceiverService @ChangedParams
        }

        $setSTFWebReceiverServiceParams = @{
            WebReceiverService        = $Configuration
            DefaultIISSite            = $DefaultIISSite
            ClassicReceiverExperience = $ClassicReceiverExperience
        }
        if ($PSBoundParameters.ContainsKey('SessionStateTimeout')) {
            $setSTFWebReceiverServiceParams['SessionStateTimeout'] = $SessionStateTimeout
        }
        Write-Verbose -Message $localizedData.CallingSetSTFWebReceiverService
        Set-STFWebReceiverService @setSTFWebReceiverServiceParams
    }
    else {

        Write-Verbose -Message $localizedData.CallingRemoveSTFWebReceiverService
        Remove-STFWebReceiverService -WebReceiverService $Configuration
    }
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $VirtualPath,

        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter()]
        [System.Boolean]
        $ClassicReceiverExperience,

        [Parameter()]
        [System.UInt32]
        $SessionStateTimeout,

        [Parameter()]
        [System.Boolean]
        $DefaultIISSite,

        [Parameter()]
        [System.String]
        $FriendlyName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $targetResource = Get-TargetResource -StoreName $StoreName -VirtualPath $VirtualPath
    If ($Ensure -eq 'Present') {
        $inCompliance = $true;
        foreach ($property in $PSBoundParameters.Keys) {
            ## FriendlyName cannot be changed after the WebReceiverService is provisioned so skip testing it
            if ($targetResource.ContainsKey($property) -and ($property -ne 'FriendlyName')) {
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
    }
    else {
        if ($targetResource.VirtualPath) {
            $inCompliance = $false
        }
        else {
            $inCompliance = $true
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

