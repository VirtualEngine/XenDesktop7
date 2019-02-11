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


Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFront.ResClusterources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $FarmName,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Port,

        [parameter(Mandatory = $true)]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $LoadBalance,

        [parameter(Mandatory = $true)]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType

    )
    begin {


    }
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop;
        
        try {
            $StoreService = Get-STFStoreService | Where-object {$_.name -eq $using:SiteName}
            $StoreFarm = Get-STFStoreFarm -StoreService $StoreService
        }
        catch { }

        $targetResource = @{
            SiteName = $StoreService.Name
            FarmName = $StoreFarm.FarmName
            port = $StoreFarm.Port
            transportType = $StoreFarm.TransportType
            servers = $StoreFarm.Servers
            LoadBalance = $StoreFarm.LoadBalance
            farmType = $StoreFarm.FarmType
            AuthType = $StoreFarm.AuthType
        };

        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $FarmName,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Port,

        [parameter(Mandatory = $true)]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $LoadBalance,

        [parameter(Mandatory = $true)]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
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
        [parameter(Mandatory = $true)]
        [System.String]
        $FarmName,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Port,

        [parameter(Mandatory = $true)]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $LoadBalance,

        [parameter(Mandatory = $true)]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure

    )
    begin {

        AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {
        Import-module Citrix.StoreFront -ErrorAction Stop
        add-pssnapin Citrix.DeliveryServices.Framework.Commands -ErrorAction Stop

        $NewClusterParams = @{
            hostBaseUrl = $using:HostBaseUrl
            farmName = $using:farmName
            port = $using:port
            transportType = $using:transportType
            sslRelayPOrt = $using:sslRelayPort
            Servers = $using:servers
            LoadBalance = $using:LoadBalance
            farmType = $using:farmType
        }

        If (Get-DSClusterId) {
            #Set-STFStoreFarm @SetStoreFarmParams | Out-Null
        }
        Else {
            Set-DSInitialConfiguration @NewClusterParams | Out-Null
        }

    } #end process
} #end function Set-TargetResource

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;

