<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	
	 Filename:     	VE_XD7StoreFrontFarm.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontFarm
	===========================================================================
#>


Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontFarm.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [System.String] $FarmName,

        [Parameter(Mandatory)]
        [Int32] $XMLport,

        [Parameter(Mandatory)]
        [System.String] $XMLtransportType,

        [Parameter(Mandatory)]
        [System.String[]] $XMLservers,

        [Parameter(Mandatory)]
        [Boolean] $LoadBalance,

        [Parameter(Mandatory)]
        [System.String] $farmType,

        [Parameter(Mandatory)]
        [System.String] $SiteName

    )
    begin {

        AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop;

        try {
            $StoreService = Get-STFStoreService | Where-object {$_.name -eq $using:SiteName}
            $StoreFarm = Get-STFStoreFarm -StoreService $StoreService
        }
        catch { }

        $targetResource = @{
            SiteName = $StoreService.Name;
            FarmName = $StoreFarm.FarmName;
            XMLport = $StoreFarm.Port
            XMLtransportType = $StoreFarm.TransportType
            XMLservers = $StoreFarm.Servers
            LoadBalance = $StoreFarm.LoadBalance
            farmType = $StoreFarm.FarmType
        };

        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [System.String] $FarmName,

        [Parameter(Mandatory)]
        [System.String] $XMLport,

        [Parameter(Mandatory)]
        [System.String] $XMLtransportType,

        [Parameter(Mandatory)]
        [System.String] $XMLservers,

        [Parameter(Mandatory)]
        [System.String] $LoadBalance,

        [Parameter(Mandatory)]
        [System.String] $farmType,

        [Parameter(Mandatory)]
        [System.String] $SiteName
    )
    process {

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

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalFunctions', 'global:Write-Host')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    param (
        [Parameter(Mandatory)]
        [System.String] $FarmName,

        [Parameter(Mandatory)]
        [Int32] $XMLport,

        [Parameter(Mandatory)]
        [System.String] $XMLtransportType,

        [Parameter(Mandatory)]
        [System.String[]] $XMLservers,

        [Parameter(Mandatory)]
        [Boolean] $LoadBalance,

        [Parameter(Mandatory)]
        [System.String] $farmType,

        [Parameter(Mandatory)]
        [System.String] $SiteName
    )
    begin {

        AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {

            $StoreFarmParams = @{
                StoreService = Get-STFStoreService | Where-object {$_.name -eq $using:SiteName};
           #     BaseUrl = $using:BaseUrl;
           #     SiteID = $using:SiteID;
           #     StoreVirtPath = $using:StoreVirtPath;
                FarmName = $using:FarmName;
                Port = $using:XMLport;
                TransportType = $using:XMLtransportType;
                Servers = $using:XMLservers;
                LoadBalance = $using:LoadBalance;
                FarmType = $using:farmType;
            }

            $null = Set-STFStoreFarm @StoreFarmParams;

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;

