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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Explicit','Anonymous')]
        [System.String]
        $AuthType,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Servers
    )
    process {

        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName };
        if ($StoreService) {
            ## This is a hack, as Get-STFStoreFarm throws an error if run twice in quick succession?!
            $null = Get-STFStoreFarm -StoreService $StoreService -FarmName $FarmName -Verbose -OutVariable StoreFarm
        }

        switch ($StoreService.service.Anonymous) {
            $True { $CurrentAuthType = 'Anonymous' }
            $False { $CurrentAuthType = 'Explicit' }
        }

        $targetResource = @{
            StoreName = $StoreService.FriendlyName
            FarmName = $StoreFarm.FarmName
            Port = $StoreFarm.Port
            TransportType = $StoreFarm.TransportType
            Servers = [System.String[]]$StoreFarm.Servers
            LoadBalance = $StoreFarm.LoadBalance
            FarmType = $StoreFarm.FarmType
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Servers,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmName,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter()]
        [ValidateSet('HTTP','HTTPS','SSL')]
        [System.String]
        $TransportType,

        [Parameter()]
        [System.Boolean]
        $LoadBalance,

        [Parameter()]
        [ValidateSet('XenApp','XenDesktop','AppController')]
        [System.String]
        $FarmType,

        [Parameter()]
        [System.String]
        $AuthVirtualPath = "/Citrix/$($StoreName)auth",

        [Parameter()]
        [System.String]
        $StoreVirtualPath = "/Citrix/$($StoreName)",

        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter()]
        [System.String[]]
        $ServiceUrls,

        [Parameter()]
        [System.UInt32]
        $SSLRelayPort,

        [Parameter()]
        [System.UInt32]
        $AllFailedBypassDuration,

        [Parameter()]
        [System.UInt32]
        $BypassDuration,

        [Parameter()]
        [System.String[]]
        $Zones,

        [Parameter()]
        [System.Boolean]
        $LockedDown,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    process {

        $targetResource = Get-TargetResource -StoreName $StoreName -AuthType $AuthType -FarmName $FarmName -Servers $Servers
        if ($Ensure -eq 'Present') {
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
        else {
            if ($targetResource.StoreName) {
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

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Explicit','Anonymous')]
        [System.String]
        $AuthType,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Servers,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmName,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter()]
        [ValidateSet('HTTP','HTTPS','SSL')]
        [System.String]
        $TransportType,

        [parameter()]
        [System.Boolean]
        $LoadBalance,

        [Parameter()]
        [ValidateSet('XenApp','XenDesktop','AppController')]
        [System.String]
        $FarmType,

        [Parameter()]
        [System.String]
        $AuthVirtualPath = "/Citrix/$($StoreName)auth",

        [Parameter()]
        [System.String]
        $StoreVirtualPath = "/Citrix/$($StoreName)",

        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter()]
        [System.String[]]
        $ServiceUrls,

        [Parameter()]
        [System.UInt32]
        $SSLRelayPort,

        [Parameter()]
        [System.UInt32]
        $AllFailedBypassDuration,

        [Parameter()]
        [System.UInt32]
        $BypassDuration,

        [Parameter()]
        [System.String[]]
        $Zones,

        [Parameter()]
        [System.Boolean]
        $LockedDown,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    process {

        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
        $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
        if ($StoreService) {
            ## This is a hack, as Get-STFStoreFarm throws an error if run twice in quick succession?!
            $null = Get-STFStoreFarm -StoreService $StoreService -FarmName $FarmName -Verbose -OutVariable StoreFarm
        }

        if ($Ensure -eq 'Present') {

            #Region Create Params hashtable
            $AllParams = @{}
            $ChangedParams = @{}
            $targetResource = Get-TargetResource -StoreName $StoreName -AuthType $AuthType -Servers $Servers -FarmName $FarmName
            foreach ($property in $PSBoundParameters.Keys) {
                if ($targetResource.ContainsKey($property)) {
                    if (!($AllParams.ContainsKey($property))) {
                        $AllParams.Add($property, $PSBoundParameters[$property])
                    }
                    $expected = $PSBoundParameters[$property];
                    $actual = $targetResource[$property];
                    if ($PSBoundParameters[$property] -is [System.String[]]) {
                        if ($actual) {
                            if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                                if (!($ChangedParams.ContainsKey($property))) {
                                    Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                                    $ChangedParams.Add($property, $PSBoundParameters[$property])
                                }
                            }
                        }
                        Else {
                            Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                            $ChangedParams.Add($property, $PSBoundParameters[$property])
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
            $AllParams.Remove('StoreName')
            $ChangedParams.Remove('StoreName')
            $AllParams.Remove('LockedDown')
            if ($FarmName.Length -gt 0) {

                $FarmNameParam = $FarmName
            }
            elseif ($StoreFarm.FarmName.length -gt 0) {

                $FarmNameParam = $StoreFarm.FarmName
            }
            else {

                $FarmNameParam = "$($StoreName)farm"
            }

            if (!($AllParams.ContainsKey('FarmName'))) {
                $AllParams.Add('FarmName', $FarmNameParam)
            }
            if (!($ChangedParams.ContainsKey('FarmName'))) {
                $ChangedParams.Add('FarmName', $FarmNameParam)
            }
            #endregion

            #Region Check for Authentication service - create if needed
            $AllParams.Remove('AuthType')
			$AllParams.Remove("AuthVirtualPath")
            if ($AuthType -eq 'Anonymous') {
                $AllParams.Add('Anonymous', $true)
                $ChangedAuth = 'Anonymous'
            }
            else {
                $Auth = Get-STFAuthenticationService -VirtualPath $AuthVirtualPath -SiteID $SiteId
                if ($Auth.VirtualPath -ne $AuthVirtualPath) {

                    Write-Verbose -Message $localizedData.RunningAddSTFAuthenicationService
                    $Auth = Add-STFAuthenticationService -VirtualPath $AuthVirtualPath -SiteID $SiteId -confirm:$false
                }
                $AllParams.Add('AuthenticationService', $Auth)
                $ChangedAuth = $Auth
            }
            #endregion

            #Region Add Servers value if not exist
            if (!($ChangedParams.ContainsKey('Servers'))) {
                $ChangedParams.Add('Servers', $Servers)
            }
            #endregion

            if ($StoreService.friendlyName -eq $StoreName) {
                if ($ChangedParams.ContainsKey('AuthType')) {
                    $ChangedParams.Remove('AuthType')
                    if ($ChangedAuth -eq 'Anonymous') {
                        $Auth = Get-STFAuthenticationService -VirtualPath $StoreService.AuthenticationServiceVirtualPath -SiteID $StoreService.SiteId
                        if ($Auth) {
                            #TODO: What do you do here?  The following doesn't work since it's in use
                            #Write-Verbose "Running Remove-STFAuthenticationService"
                            #$Auth | Remove-STFAuthenticationService -confirm:$false
                        }
                    }
                    else {
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
                if ($ChangedParams.ContainsKey('LockedDown')) {
                    Write-Verbose -Message $localizedData.RunningSetSTFStoreService
                    Set-STFStoreService -StoreService $StoreService -LockedDown $LockedDown -confirm:$false
                    $ChangedParams.Remove('LockedDown')
                }

                If ($ChangedParams.ContainsKey('AuthVirtualPath')) {
                    $ChangedParams.Remove('AuthVirtualPath')
                }
                if ($StoreFarm) {
                    #update params
                    $ChangedParams.Add('StoreService', $StoreService)

                    #Update settings
                    Write-Verbose -Message $localizedData.RunningSetSTFStoreFarm
                    Set-STFStoreFarm @ChangedParams -confirm:$false
                }
                else {
                    #update params
                    $KeysToRemove = 'AuthenticationService','Anonymous'
                    $KeysToRemove | ForEach-Object { $AllParams.Remove($_) }

                    #Create farm
                    Write-Verbose -Message $localizedData.RunningNewSTFStoreFarm
                    New-STFStoreFarm @AllParams -confirm:$false
                    #Add farm to storeservice
                    Write-Verbose -Message $localizedData.RunningAddSTFStoreFarm
                    $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
                    Add-STFStoreFarm -Farm $AllParams.FarmName -StoreService $StoreService
                }
            }
            else {
                #update params
                $AllParams.Add('FriendlyName', $StoreName)
                $AllParams.Add('VirtualPath', $StoreVirtualPath)
                $AllParams.Add('SiteId', $SiteId)

                #Create
                Write-Verbose -Message $localizedData.RunningAddSTFStoreService
                Add-STFStoreService @AllParams -confirm:$false

                if ($ChangedParams.ContainsKey('LockedDown')) {
                    #This setting isn't available to be set via the Add-STFStoreService
                    Write-Verbose -Message $localizedData.RunningSetSTFStoreFarmLockedDown
                    $StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
                    Set-STFStoreService -StoreService $StoreService -LockedDown $LockedDown -confirm:$false
                }

            }
        }
        else {
            #Uninstall
            Write-Verbose -Message $localizedData.RunningRemoveSTFStoreService
            $AuthVirtPath = $StoreService.AuthenticationServiceVirtualPath
            $SiteId = $StoreService.SiteId
            $StoreService | Remove-STFStoreService -confirm:$false
            Write-Verbose -Message ($localizedData.RunningGetSTFAuthenticationService -f $AuthVirtPath)
            $Auth = Get-STFAuthenticationService -VirtualPath $AuthVirtPath -SiteID $SiteId
            if ($Auth) {
                Write-Verbose -Message $localizedData.RunningRemoveSTFAuthenicationService
                $Auth | Remove-STFAuthenticationService -confirm:$false
            }
        }

    } #end process
} #end function Set-TargetResource


Export-ModuleMember -Function *-TargetResource;
