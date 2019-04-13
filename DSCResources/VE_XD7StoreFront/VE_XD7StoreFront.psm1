<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization:
	 Filename:     	VE_XD7StoreFront.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFront
	===========================================================================
#>


Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFront.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    [OutputType([System.Collections.Hashtable])]
    param (

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $SiteId
    )
    process {

        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

        try {

            $Deployment = Get-STFDeployment -SiteId $SiteId
        }
        catch { }

        $targetResource = @{
            SiteId = $Deployment.SiteId
            HostBaseUrl = $Deployment.HostBaseUrl
            Ensure = $null -ne $Deployment
        };

        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $SiteId,

        [Parameter()]
        [System.String]
        $HostBaseUrl = 'http://localhost',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    process {

        $targetResource = Get-TargetResource -SiteId $SiteId
        if ($Ensure -eq 'Present') {

            if (($targetResource.SiteId -eq $SiteId) -and ($targetResource.HostBaseUrl -eq $HostBaseUrl)) {
                Write-Verbose -Message ($localizedData.ResourceInDesiredState -f $SiteId)
                return $true
            }
            else {
                Write-Verbose -Message ($localizedData.ResourceNotInDesiredState -f $SiteId)
                return $false
            }
        }
        else {

            if ($targetResource.SiteId) {
                Write-Verbose -Message ($localizedData.ResourceNotInDesiredState -f $SiteId)
                return $false
            }
            else {
                Write-Verbose -Message ($localizedData.ResourceInDesiredState -f $SiteId)
                return $true
            }
        }

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    param (
        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $SiteId,

        [Parameter()]
        [System.String]
        $HostBaseUrl = 'http://localhost',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'

    )
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
        $Deployment = Get-STFDeployment -SiteId $SiteId
        if ($Ensure -eq 'Present') {
            if ($Deployment) {
                Set-STFDeployment -HostBaseUrl $HostBaseUrl -confirm:$false | Out-Null
            }
            else {
                Add-STFDeployment -HostBaseUrl $HostBaseUrl -SiteId $SiteId -confirm:$false | Out-Null
            }
        }
        else {
            #Uninstall
            Clear-STFDeployment -SiteId $SiteId | Out-Null
        }

    } #end process
} #end function Set-TargetResource

Export-ModuleMember -Function *-TargetResource;
