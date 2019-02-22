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


#TODO: Test switching auth - See TODOs below

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
        [System.String[]]
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
        [System.String[]]
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
        [System.String[]]
        $Zones,

        [parameter()]
        [System.Boolean]
        $LockedDown,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure

    )
    begin {

        #AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;
        
        try {
            $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
            $StoreFarm = Get-STFStoreFarm -StoreService $StoreService
        }
        catch { }

        switch ($StoreService.service.Anonymous) {
            $True {$CurrentAuthType = "Anonymous"}
            $False {$CurrentAuthType = "Explicit"}
        }

        $targetResource = @{
            StoreName = $StoreService.FriendlyName
            FarmName = $StoreFarm.FarmName
            port = $StoreFarm.Port
            transportType = $StoreFarm.TransportType
            servers = [System.String[]]$StoreFarm.Servers
            LoadBalance = $StoreFarm.LoadBalance
            farmType = $StoreFarm.FarmType
            AuthType = $CurrentAuthType
            AuthVirtualPath = $StoreService.AuthenticationServiceVirtualPath
            StoreVirtualPath = $StoreService.VirtualPath
            SiteId = $StoreService.SiteId
            ServiceUrls = [System.String[]]$StoreFarm.ServiceUrls
            SSLRelayPort = $StoreFarm.SSLRelayPort
            AllFailedBypassDuration = $StoreFarm.AllFailedBypassDuration
            BypassDuration = $StoreFarm.BypassDuration
            FriendlyName = $StoreService.FriendlyName
            Zones = $StoreFarm.Zones
            LockedDown = $storeservice.service.LockedDown
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
        [System.String[]]
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
        [System.String[]]
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
        [System.String[]]
        $Zones,

        [parameter()]
        [System.Boolean]
        $LockedDown,

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
        [System.String[]]
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
        [System.String[]]
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
        [System.String[]]
        $Zones,

        [parameter()]
        [System.Boolean]
        $LockedDown,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure

    )
    begin {

        #AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
        $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName}
        If ($StoreService) {
            $StoreFarm = Get-STFStoreFarm -StoreService $StoreService
        }

        If ($Ensure -eq 'Present') {


            #Region Create Params hashtable
            $AllParams = @{}
            $ChangedParams = @{}
            $targetResource = Get-TargetResource @PSBoundParameters;
            foreach ($property in $PSBoundParameters.Keys) {
                if ($targetResource.ContainsKey($property)) {
                    if (!($AllParams.ContainsKey($property))) {
                        $AllParams.Add($property,$PSBoundParameters[$property])
                    }
                    $expected = $PSBoundParameters[$property];
                    $actual = $targetResource[$property];
                    if ($PSBoundParameters[$property] -is [System.String[]]) {
                        if ($actual) {
                            if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                                if (!($ChangedParams.ContainsKey($property))) {
                                    Write-Verbose "Adding $property to ChangedParams"
                                    $ChangedParams.Add($property,$PSBoundParameters[$property])
                                }
                            }
                        }
                        Else {
                            Write-Verbose "Adding $property to ChangedParams"
                            $ChangedParams.Add($property,$PSBoundParameters[$property])
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
            $AllParams.Remove("StoreName")
            $ChangedParams.Remove("StoreName")
            $AllParams.Remove('LockedDown')
            If ($FarmName.Length -gt 0) {
                $FarmNameParam = $FarmName
            }
            elseif ($StoreFarm.FarmName.length -gt 0) {
                $FarmNameParam = $StoreFarm.FarmName
            }
            Else {
                $FarmNameParam = "$($StoreName)farm"
            }
            if (!($AllParams.ContainsKey("FarmName"))) {
                $AllParams.Add("FarmName",$FarmNameParam)
            }
            if (!($ChangedParams.ContainsKey("FarmName"))) {
                $ChangedParams.Add("FarmName",$FarmNameParam)
            }
            #endregion

            #Region Check for Authentication service - create if needed
            $AllParams.Remove("AuthType")
            If ($AuthType -eq "Anonymous") {
                $AllParams.Add("Anonymous",$true)
                $ChangedAuth = "Anonymous"
            }
            Else {
                $Auth = Get-STFAuthenticationService -VirtualPath $AuthVirtualPath -SiteID $SiteId
                If ($Auth.VirtualPath -ne $AuthVirtualPath) {
                    Write-Verbose "Running Add-STFAuthenicationService"
                    $Auth = Add-STFAuthenticationService -VirtualPath $AuthVirtualPath -SiteID $SiteId -confirm:$false
                }
                $AllParams.Add("AuthenticationService",$Auth)
                $ChangedAuth = $Auth
            }
            #endregion

            #Region Add Servers value if not exist
            If (!($ChangedParams.ContainsKey("Servers"))) {
                $ChangedParams.Add("Servers",$Servers)
            }
            #endregion

            If ($StoreService.friendlyName -eq $StoreName) {
                If ($ChangedParams.ContainsKey("AuthType")) {
                    $ChangedParams.Remove("AuthType")
                    If ($ChangedAuth -eq "Anonymous") {
                        $Auth = Get-STFAuthenticationService -VirtualPath $StoreService.AuthenticationServiceVirtualPath -SiteID $StoreService.SiteId
                        If ($Auth) {
                            #TODO: What do you do here?  The following doesn't work since it's in use
                            #Write-Verbose "Running Remove-STFAuthenticationService"
                            #$Auth | Remove-STFAuthenticationService -confirm:$false
                        }
                    }
                    Else {
                        #TODO: Fix this.  It gets following error
                            #set-stfstoreservice : An error occurred while updating the Store service: 
                            # System.NullReferenceException: Object reference not set to an instance of an object.
                            #   at
                            #Citrix.StoreFront.Model.Store.StoreService.Citrix.StoreFront.Model.IAuthenticatedService.RemoveAuthenticationService(AuthenticationServiceauthenticationService)
                            #   at Citrix.StoreFront.Stores.Cmdlets.SetStoreService.ProcessRecord().
                            #At line:1 char:1
                        #Write-Verbose "Running Set-STFStoreService"
                        #Set-STFStoreService -StoreService $StoreService -AuthenticationService $Auth -Confirm:$false
                    }
                }
                If ($ChangedParams.ContainsKey('LockedDown')) {
                    Write-Verbose "Running Set-STFStoreFarm"
                    Set-STFStoreService -StoreService $StoreService -LockedDown $LockedDown -confirm:$false
                    $ChangedParams.Remove('LockedDown')
                }

                If ($StoreFarm) {
                    #update params
                    $ChangedParams.Add("StoreService",$StoreService)

                    #Update settings
                    Write-Verbose "Running Set-STFStoreFarm"
                    Set-STFStoreFarm @ChangedParams -confirm:$false
                }
                Else {
                    #update params
                    $KeysToRemove = "AuthenticationService","Anonymous"
                    $KeysToRemove | ForEach-Object {$AllParams.Remove($_)}

                    #Create farm
                    Write-Verbose "Running New-STFStoreFarm"
                    New-STFStoreFarm @AllParams -confirm:$false
                    #Add farm to storeservice
                    Write-Verbose "Running Add-STFStoreFarm"
                    $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName}
                    Add-STFStoreFarm -Farm $AllParams.FarmName -StoreService $StoreService
                }
            }
            Else {
                #update params
                $AllParams.Add("FriendlyName",$StoreName)
                $AllParams.Add("VirtualPath",$StoreVirtualPath)
                $AllParams.Add("SiteId",$SiteId)

                #Create
                Write-Verbose "Running Add-STFStoreService"
                Add-STFStoreService @AllParams -confirm:$false

                If ($ChangedParams.ContainsKey('LockedDown')) {
                    #This setting isn't available to be set via the Add-STFStoreService
                    Write-Verbose "Running Set-STFStoreFarm for LockedDown setting"
                    $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName}
                    Set-STFStoreService -StoreService $StoreService -LockedDown $LockedDown -confirm:$false
                }

            }
        }
        Else {
            #Uninstall
            Write-Verbose "Running Remove-STFStoreService"
            $AuthVirtPath = $StoreService.AuthenticationServiceVirtualPath
            $SiteId = $StoreService.SiteId
            $StoreService | Remove-STFStoreService -confirm:$false
            Write-Verbose "Running Get-STFAuthenticationService -VirtualPath $AuthVirtPath -SiteID $SiteId"
            $Auth = Get-STFAuthenticationService -VirtualPath $AuthVirtPath -SiteID $SiteId
            If ($Auth) {
                Write-Verbose "Running Remove-STFAuthenticationService"
                $Auth | Remove-STFAuthenticationService -confirm:$false
            }
        }

    } #end process
} #end function Set-TargetResource

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
#Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;

