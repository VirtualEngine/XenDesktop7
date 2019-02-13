<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	
	 Filename:     	VE_XD7StoreFrontStore.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontStore
	===========================================================================
#>


Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontStore.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType,

        [parameter()]
        [System.String]
        $FarmName,

        [parameter()]
        [System.UInt32]
        $Port,

        [parameter()]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter()]
        [System.Boolean]
        $LoadBalance,

        [parameter()]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter()]
        [System.String]
        $VirtualPath="/Citrix/$($StoreName)auth",

        [parameter()]
        [System.UInt64]
        $SiteId,

        [parameter()]
        [System.String]
        $ServiceUrls,

        [parameter()]
        [System.UInt32]
        $SSLRelayPort,

        [parameter()]
        [System.UInt32]
        $AllFailedBypassDuration,

        [parameter()]
        [System.UInt32]
        $BypassDuration,

        [parameter()]
        [System.String]
        $Zones,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure

    )
    begin {

        #AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop;
        
        try {
            $StoreService = Get-STFStoreService | Where-object {$_.name -eq $StoreName};
            $StoreFarm = Get-STFStoreFarm -StoreService $StoreService
        }
        catch { }

        switch ($StoreFarm.service.Anonymous) {
            $True {$CurrentAuthType = "Anonymous"}
            $False {$CurrentAuthType = "Explicit"}
        }

        $targetResource = @{
            StoreName = $StoreService.Name
            FarmName = $StoreFarm.FarmName
            port = $StoreFarm.Port
            transportType = $StoreFarm.TransportType
            servers = $StoreFarm.Servers
            LoadBalance = $StoreFarm.LoadBalance
            farmType = $StoreFarm.FarmType
            AuthType = $CurrentAuthType
            VirtualPath = $StoreService.VirtualPath
            SiteId = $StoreService.SiteId
            ServiceUrls = $StoreFarm.ServiceUrls
            SSLRelayPort = $StoreFarm.SSLRelayPort
            AllFailedBypassDuration = $StoreFarm.AllFailedBypassDuration
            BypassDuration = $StoreFarm.BypassDuration
            FriendlyName = $StoreService.FriendlyName
            Zones = $StoreFarm.Zones
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
        $StoreName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType,

        [parameter()]
        [System.String]
        $FarmName,

        [parameter()]
        [System.UInt32]
        $Port,

        [parameter()]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter()]
        [System.Boolean]
        $LoadBalance,

        [parameter()]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter()]
        [System.String]
        $VirtualPath="/Citrix/$($StoreName)auth",

        [parameter()]
        [System.UInt64]
        $SiteId,

        [parameter()]
        [System.String]
        $ServiceUrls,

        [parameter()]
        [System.UInt32]
        $SSLRelayPort,

        [parameter()]
        [System.UInt32]
        $AllFailedBypassDuration,

        [parameter()]
        [System.UInt32]
        $BypassDuration,

        [parameter()]
        [System.String]
        $Zones,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure

    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;
        If ($Ensure -eq 'Present') {
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
        }
        Else {
            If ($targetResource.StoreName) {
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
        $StoreName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType,

        [parameter()]
        [System.String]
        $FarmName,

        [parameter()]
        [System.UInt32]
        $Port,

        [parameter()]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter()]
        [System.Boolean]
        $LoadBalance,

        [parameter()]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter()]
        [System.String]
        $VirtualPath="/Citrix/$($StoreName)auth",

        [parameter()]
        [System.UInt64]
        $SiteId,

        [parameter()]
        [System.String]
        $ServiceUrls,

        [parameter()]
        [System.UInt32]
        $SSLRelayPort,

        [parameter()]
        [System.UInt32]
        $AllFailedBypassDuration,

        [parameter()]
        [System.UInt32]
        $BypassDuration,

        [parameter()]
        [System.String]
        $Zones,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure

    )
    begin {

        #AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop

        #Add Mandatory Params
        $StoreParams = @{
            StoreName = $StoreName
            servers = $Servers
        }
        #Add Optional Params but only if wrong
        foreach ($property in $PSBoundParameters.Keys) {
            if ($targetResource.ContainsKey($property)) {
                $expected = $PSBoundParameters[$property];
                $actual = $targetResource[$property];
                if ($PSBoundParameters[$property] -is [System.String[]]) {
                    if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                        $StoreParams.Add($property,$PSBoundParameters[$property])
                    }
                }
                elseif ($expected -ne $actual) {
                    $StoreParams.Add($property,$PSBoundParameters[$property])
                }
            }
        }

        If ($Ensure -eq 'Present') {
            $StoreParams.Remove("AuthType")
            If ($AuthType -eq "Anonymous") {
                $StoreParams.Add("Anonymous",$true)
            }
            Else {
                $Auth = Get-STFAuthenticationService -VirtualPath $VirtualPath -SiteID $SiteId
                If ($Auth.VirtualPath -ne $VirtualPath) {
                    $Auth = Add-STFAuthenticationService -VirtualPath $VirtualPath -SiteID $SiteId
                }
                $StoreParams.Add("AuthenticationService",$Auth)
            }

            $StoreService = Get-STFStoreService | Where-object {$_.name -eq $StoreName}
            If ($StoreService.Name -eq $StoreName) {
                #Update settings
                Set-STFStoreService @StoreParams
            }
            Else {
                #Create
                Add-STFStoreService @StoreParams
            }
        }
        Else {
            #Uninstall
            $StoreService | Remove-STFStoreService -confirm:$false
        }

    } #end process
} #end function Set-TargetResource

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
#Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;

