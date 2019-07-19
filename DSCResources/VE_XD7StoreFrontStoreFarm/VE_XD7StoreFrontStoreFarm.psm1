<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	Cerner Corporation
	 Filename:     	VE_XD7StoreFrontStoreFarm.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontStoreFarm
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontStoreFarm.Resources.psd1;

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
		$FarmName
	)
    process {

        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

		Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName }
        if ($StoreService) {
            ## This is a hack, as Get-STFStoreFarm throws an error if run twice in quick succession?!
            $null = Get-STFStoreFarm -StoreService $StoreService -FarmName $FarmName -Verbose -OutVariable StoreFarm
        }

        $targetResource = @{
            StoreName = [System.String]$StoreService.FriendlyName
            FarmName = [System.String]$StoreFarm.FarmName
            Port = [System.UInt32]$StoreFarm.Port
            TransportType = [System.String]$StoreFarm.TransportType
            Servers = [System.String[]]$StoreFarm.Servers
            LoadBalance = [System.Boolean]$StoreFarm.LoadBalance
            FarmType = [System.String]$StoreFarm.FarmType
            ServiceUrls = [System.String[]]$StoreFarm.ServiceUrls
            SSLRelayPort = [System.UInt32]$StoreFarm.SSLRelayPort
            AllFailedBypassDuration = [System.UInt32]$StoreFarm.AllFailedBypassDuration
            BypassDuration = [System.UInt32]$StoreFarm.BypassDuration
            Zones = [System.String[]]$StoreFarm.Zones
			TicketTimeToLive = [System.UInt32]$StoreFarm.TicketTimeToLive
			RadeTicketTimeToLive = [System.UInt32]$StoreFarm.RadeTicketTimeToLive
			MaxFailedServersPerRequest = [System.UInt32]$StoreFarm.MaxFailedServersPerRequest
			Product = [System.String]$StoreFarm.Product
			RestrictPoPs = [System.String]$StoreFarm.RestrictPoPs
			FarmGuid = [System.String]$StoreFarm.FarmGuid
		};

        return $targetResource;

    } #end process
}


function Set-TargetResource
{
	[CmdletBinding()]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$StoreName,

		[parameter(Mandatory = $true)]
		[System.String]
		$FarmName,

        [Parameter()]
		[ValidateSet("XenApp","XenDesktop","AppController","VDIinaBox","Store")]
		[System.String]
		$FarmType,

        [Parameter()]
		[System.String[]]
		$Servers,

        [Parameter()]
		[System.String[]]
		$ServiceUrls,

        [Parameter()]
		[System.UInt32]
		$Port,

        [Parameter()]
		[ValidateSet("HTTP","HTTPS","SSL")]
		[System.String]
		$TransportType,

        [Parameter()]
		[System.UInt32]
		$SSLRelayPort,

        [Parameter()]
		[System.Boolean]
		$LoadBalance,

        [Parameter()]
		[System.UInt32]
		$AllFailedBypassDuration,

        [Parameter()]
		[System.UInt32]
		$BypassDuration,

        [Parameter()]
		[System.UInt32]
		$TicketTimeToLive,

        [Parameter()]
		[System.UInt32]
		$RadeTicketTimeToLive,

        [Parameter()]
		[System.UInt32]
		$MaxFailedServersPerRequest,

        [Parameter()]
		[System.String[]]
		$Zones,

        [Parameter()]
		[System.String]
		$Product,

        [Parameter()]
		[System.String]
		$RestrictPoPs,

        [Parameter()]
		[System.String]
		$FarmGuid,

		[Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'

	)
    process {

        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
		Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName }
        if ($StoreService) {
            ## This is a hack, as Get-STFStoreFarm throws an error if run twice in quick succession?!
            $null = Get-STFStoreFarm -StoreService $StoreService -FarmName $FarmName -Verbose -OutVariable StoreFarm
        }
	
		if ($Ensure -eq 'Present') {

			if ($StoreFarm.FarmName -ne $FarmName) {
				#Create new one
				$Params = $PSBoundParameters
				$Params.Remove('StoreName')
				$Params.Add('StoreService',$StoreService)
				Add-STFStoreFarm @Params
			}
			else {
				#Update existing
				$ChangedParams = @{
					StoreService = $StoreService
					FarmName = $FarmName
				}
				If ($Servers) {
					$ChangedParams.Add('Servers',$Servers)
				}
				$targetResource = Get-TargetResource -StoreName $StoreName -FarmName $FarmName
				foreach ($property in $PSBoundParameters.Keys) {
					if ($targetResource.ContainsKey($property)) {
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
				$ChangedParams.Remove('StoreName')
				Write-Verbose -Message ($localizedData.RunningSetSTFStoreFarm)
				Set-STFStoreFarm @ChangedParams
			}
		}
		else {
			Write-Verbose -Message ($localizedData.RunningRemoveSTFStoreFarm)
			Remove-STFStoreFarm -FarmName $FarmName -StoreService $StoreService #-confirm:$false
		}

    } #end process

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
		$FarmName,

        [Parameter()]
		[ValidateSet("XenApp","XenDesktop","AppController","VDIinaBox","Store")]
		[System.String]
		$FarmType,

        [Parameter()]
		[System.String[]]
		$Servers,

        [Parameter()]
		[System.String[]]
		$ServiceUrls,

        [Parameter()]
		[System.UInt32]
		$Port,

        [Parameter()]
		[ValidateSet("HTTP","HTTPS","SSL")]
		[System.String]
		$TransportType,

        [Parameter()]
		[System.UInt32]
		$SSLRelayPort,

        [Parameter()]
		[System.Boolean]
		$LoadBalance,

        [Parameter()]
		[System.UInt32]
		$AllFailedBypassDuration,

        [Parameter()]
		[System.UInt32]
		$BypassDuration,

        [Parameter()]
		[System.UInt32]
		$TicketTimeToLive,

        [Parameter()]
		[System.UInt32]
		$RadeTicketTimeToLive,

        [Parameter()]
		[System.UInt32]
		$MaxFailedServersPerRequest,

        [Parameter()]
		[System.String[]]
		$Zones,

        [Parameter()]
		[System.String]
		$Product,

        [Parameter()]
		[System.String]
		$RestrictPoPs,

        [Parameter()]
		[System.String]
		$FarmGuid,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'

		)
    process {

		$targetResource = Get-TargetResource -StoreName $StoreName -FarmName $FarmName
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
            if ($targetResource.FarmName) {
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
}

Export-ModuleMember -Function *-TargetResource

