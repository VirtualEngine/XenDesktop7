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


#TODO: Issue creating a store if the auth service already exists
#TODO: Test switching auth
#TODO: WebApplicationAlreadyExists erro

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
        $FarmName="$($StoreName)farm",

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
        $AuthVirtualPath="/Citrix/$($StoreName)auth",

        [parameter()]
        [System.String]
        $StoreVirtualPath="/Citrix/$($StoreName)",

        [parameter()]
        [System.UInt64]
        $SiteId=1,

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
            $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
            $StoreFarm = Get-STFStoreFarm -StoreService $StoreService
        }
        catch { }

        switch ($StoreService.service.Anonymous) {
            $True {$CurrentAuthType = "Anonymous"}
            $False {$CurrentAuthType = "Explicit"}
        }
        $StrServers = ($StoreFarm.Servers) -join(",")

        $targetResource = @{
            StoreName = $StoreService.FriendlyName
            FarmName = $StoreFarm.FarmName
            port = $StoreFarm.Port
            transportType = $StoreFarm.TransportType
            servers = $strServers
            LoadBalance = $StoreFarm.LoadBalance
            farmType = $StoreFarm.FarmType
            AuthType = $CurrentAuthType
            AuthVirtualPath = $StoreService.AuthenticationServiceVirtualPath
            StoreVirtualPath = $StoreService.VirtualPath
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
        $FarmName="$($StoreName)farm",

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
        $AuthVirtualPath="/Citrix/$($StoreName)auth",

        [parameter()]
        [System.String]
        $StoreVirtualPath="/Citrix/$($StoreName)",

        [parameter()]
        [System.UInt64]
        $SiteId=1,

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
        $FarmName="$($StoreName)farm",

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
        $AuthVirtualPath="/Citrix/$($StoreName)auth",

        [parameter()]
        [System.String]
        $StoreVirtualPath="/Citrix/$($StoreName)",

        [parameter()]
        [System.UInt64]
        $SiteId=1,

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
        $ArrServers = $Servers.Split(",")
        $StoreParams = @{
            FriendlyName = $StoreName
            servers = $ArrServers
            VirtualPath = $StoreVirtualPath
        }
        $FarmParams = @{}
        $AllStoreParams = @{
            FriendlyName = $StoreName
            servers = $ArrServers
            VirtualPath = $StoreVirtualPath
            SiteId = $SiteId
        }
        #Add Optional Params but only if wrong
        $targetResource = Get-TargetResource @PSBoundParameters;
        foreach ($property in $PSBoundParameters.Keys) {
            if ($targetResource.ContainsKey($property)) {
                if (!($AllStoreParams.ContainsKey($property))) {
                    $AllStoreParams.Add($property,$PSBoundParameters[$property])
                }
                $expected = $PSBoundParameters[$property];
                $actual = $targetResource[$property];
                if ($PSBoundParameters[$property] -is [System.String[]]) {
                    if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                        if (!($FarmParams.ContainsKey($property))) {
                            Write-Verbose "Adding $property to FarmParams"
                            $FarmParams.Add($property,$PSBoundParameters[$property])
                        }
                    }
                }
                elseif ($expected -ne $actual) {
                    if (!($FarmParams.ContainsKey($property))) {
                        Write-Verbose "Adding $property to FarmParams"
                        $FarmParams.Add($property,$PSBoundParameters[$property])
                    }
                }
            }
        }

        If ($Ensure -eq 'Present') {
            $FarmParams.Remove("AuthType")
            $AllStoreParams.Remove("AuthType")
            If ($AuthType -eq "Anonymous") {
                $AllStoreParams.Add("Anonymous",$true)
            }
            Else {
                $Auth = Get-STFAuthenticationService -VirtualPath $AuthVirtualPath -SiteID $SiteId
                If ($Auth.VirtualPath -ne $AuthVirtualPath) {
                    Write-Verbose "Running Add-STFAuthenicationService"
                    $Auth = Add-STFAuthenticationService -VirtualPath $AuthVirtualPath -SiteID $SiteId -confirm:$false
                }
                $AllStoreParams.Add("AuthenticationService",$Auth)
            }

            $FarmParams.Remove("StoreName")
            $AllStoreParams.Remove("StoreName")
            $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName}
            $StoreFarm = Get-STFStoreFarm -StoreService $StoreService
            If ($FarmParams.Count -gt 0) {
                $FarmParams.Add("StoreService",$StoreService)
                if (!($FarmParams.ContainsKey("FarmName"))) {
                    $FarmParams.Add("FarmName",$StoreFarm.FarmName)
                }
                if (!($FarmParams.ContainsKey("Servers"))) {
                    $FarmParams.Add("Servers",$ArrServers)
                }
            }

            $FarmParams | Export-Clixml c:\Temp\farmparams.xml
            $AllStoreParams | Export-Clixml c:\Temp\allstoreparams.xml
            If ($StoreService.friendlyName -eq $StoreName) {
                If ($FarmParams.Count -gt 0) {
                    #Update settings
                    Write-Verbose "Running Set-STFStoreFarm"
                    Set-STFStoreFarm @FarmParams -confirm:$false
                }
            }
            Else {
                #Create
                Write-Verbose "Running Add-STFStoreService"
                Add-STFStoreService @AllStoreParams -confirm:$false
            }
        }
        Else {
            #Uninstall
            $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName}
            $Auth = Get-STFAuthenticationService -VirtualPath $StoreService.AuthenticationServiceVirtualPath -SiteID $StoreService.SiteId
            Write-Verbose "Running Remove-STFStoreService"
            $StoreService | Remove-STFStoreService -confirm:$false
            Write-Verbose "Running Remove-STFAuthenticationService"
            $Auth | Remove-STFAuthenticationService -confirm:$false
        }

    } #end process
} #end function Set-TargetResource

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
#Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;

