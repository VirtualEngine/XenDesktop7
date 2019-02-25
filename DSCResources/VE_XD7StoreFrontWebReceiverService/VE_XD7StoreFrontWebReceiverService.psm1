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
        [parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualPath,

        [parameter()]
        [System.UInt64]
        $SiteId=1,

        [System.Boolean]
        $ClassicReceiverExperience,

        [System.String]
        $FriendlyName,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {
        Write-Verbose "Calling Get-STFStoreService for $StoreName"
        $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
        Write-Verbose "Calling Get-STFWebReceiverService"
        $Configuration = Get-STFWebReceiverService -StoreService $StoreService
    }
    catch {
        Write-Verbose "Trapped error getting web receiver service. Error: $($Error[0].Exception.Message)"
    }

    $returnValue = @{
        StoreName = [System.String]$StoreName
        VirtualPath = [System.String]$Configuration.VirtualPath
        SiteId = [System.UInt64]$Configuration.SiteId
        ClassicReceiverExperience = [System.Boolean]$Configuration.IDONTKNOWWHERETHISIS
        FriendlyName = [System.String]$Configuration.FriendlyName
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

        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualPath,

        [parameter()]
        [System.UInt64]
        $SiteId=1,

        [System.Boolean]
        $ClassicReceiverExperience,

        [System.String]
        $FriendlyName,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

    try {
        Write-Verbose "Calling Get-STFStoreService for $StoreName"
        $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
        Write-Verbose "Calling Get-STFWebReceiverService"
        $Configuration = Get-STFWebReceiverService -StoreService $StoreService
    }
    catch {
        Write-Verbose "Trapped error getting web receiver service. Error: $($Error[0].Exception.Message)"
    }

    $ChangedParams = @{
        StoreService = $StoreService
        VirtualPath = $VirtualPath
        SiteId = $SiteId
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
    If ($Ensure -eq 'Present') {
        If ($Configuration) {
            Write-Verbose "Calling Set-STFWebReceiverService"
            Set-STFWebReceiverService @ChangedParams
        }
        Else {
            Write-Verbose "Calling Add-STFWebReceiverService"
            Add-STFWebReceiverService @ChangedParams
        }
    }
    Else {
        Write-Verbose "Calling Remove-STFWebReceiverService"
        Remove-STFWebReceiverService -WebReceiverService $Configuration
    }
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

        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualPath,

        [parameter()]
        [System.UInt64]
        $SiteId=1,

        [System.Boolean]
        $ClassicReceiverExperience,

        [System.String]
        $FriendlyName,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

        $targetResource = Get-TargetResource @PSBoundParameters;
        If ($Ensure -eq 'Present') {
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
        }
        Else {
            If ($targetResource.VirtualPath) {
                $inCompliance = $false
            }
            Else {
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

