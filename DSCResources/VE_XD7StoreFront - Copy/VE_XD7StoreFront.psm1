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
    [OutputType([System.Collections.Hashtable])]
    param (

        [parameter(Mandatory = $true)]
        [System.UInt64]
        $SiteId,

        [parameter()]
        [System.String]
        $HostBaseUrl="http://localhost",

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    begin {

        #AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop;
        
        try {
            $Deployment = Get-STFDeployment -SiteId $SiteId
        }
        catch { }

        $targetResource = @{
            SiteId = $Deployment.SiteId
            HostBaseUrl = $Deployment.HostBaseUrl
        };

        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [parameter(Mandatory = $true)]
        [System.UInt64]
        $SiteId,

        [parameter()]
        [System.String]
        $HostBaseUrl="http://localhost",

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;
        If ($Ensure -eq 'Present') {
            If (($targetResource.SiteId -eq $SiteId) -and ($targetResource.HostBaseUrl -eq $HostBaseUrl)) {
                return $true
            }
            Else {
                return $false
            }
        }
        Else {
            If ($targetResource.SiteId) {
                return $false
            }
            Else {
                return $true
            }
        }

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalFunctions', 'global:Write-Host')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    param (
        [parameter(Mandatory = $true)]
        [System.UInt64]
        $SiteId,

        [parameter(Mandatory = $true)]
        [System.String]
        $HostBaseUrl="http://localhost",

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'

    )
    begin {

        #AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {
        Import-module Citrix.StoreFront -ErrorAction Stop
        $Deployment = Get-STFDeployment -SiteId $SiteId
        If ($Ensure -eq 'Present') {
            If ($Deployment) {
                Set-STFDeployment -HostBaseUrl $HostBaseUrl -confirm:$false | Out-Null
            }
            Else {
                Add-STFDeployment -HostBaseUrl $HostBaseUrl -SiteId $SiteId -confirm:$false | Out-Null
            }
        }
        Else {
            #Uninstall
            Clear-STFDeployment -SiteId $SiteId | Out-Null
        }

    } #end process
} #end function Set-TargetResource

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
#Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;

