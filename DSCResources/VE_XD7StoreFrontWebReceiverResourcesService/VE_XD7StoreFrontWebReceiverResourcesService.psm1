<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	Cerner Corporation
	 Filename:     	VE_XD7StoreFrontWebReceiverResourcesService.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontWebReceiverResourcesService
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontWebReceiverResourcesService.Resources.psd1;

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$StoreName
	)
    process {

		Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;
		#Citrix.StoreFront.WebReceiver

		Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName };
        if ($StoreService) {
			Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverService
			$WebReceiverService = Get-STFWebReceiverService -StoreService $StoreService
			Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverResourcesService
			$WebReceiverResourcesService = Get-STFWebReceiverResourcesService -WebReceiverService $WebReceiverService
		}

        $targetResource = @{
			StoreName = [System.String]$StoreName
			PersistentIconCacheEnabled = [System.Boolean]$WebReceiverResourcesService.PersistentIconCacheEnabled
			IcaFileCacheExpiry = [System.UInt32]$WebReceiverResourcesService.IcaFileCacheExpiry
			IconSize = [System.UInt32]$WebReceiverResourcesService.IconSize
			ShowDesktopViewer = [System.Boolean]$WebReceiverResourcesService.ShowDesktopViewer
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

        [Parameter()]
		[System.Boolean]
		$PersistentIconCacheEnabled,

        [Parameter()]
		[System.UInt32]
		$IcaFileCacheExpiry,

        [Parameter()]
		[System.UInt32]
		$IconSize,

        [Parameter()]
		[System.Boolean]
		$ShowDesktopViewer
	)
    process {

        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName };
        if ($StoreService) {
			Write-Verbose -Message $localizedData.CallingGetSTFWebReceiverService
			$WebReceiverService = Get-STFWebReceiverService -StoreService $StoreService
		}

        $ChangedParams = @{
            WebReceiverService = $WebReceiverService
        }
        $targetResource = Get-TargetResource -StoreName $StoreName;
        foreach ($property in $PSBoundParameters.Keys) {
            if ($targetResource.ContainsKey($property)) {
                $expected = $PSBoundParameters[$property];
                $actual = $targetResource[$property];
                if ($actual) {
                    if ($PSBoundParameters[$property] -is [System.String[]]) {
                        if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                            if (!($ChangedParams.ContainsKey($property))) {
                                Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                                $ChangedParams.Add($property, $PSBoundParameters[$property])
                            }
                        }
                    }
                    elseif ($expected -ne $actual) {
                        if (!($ChangedParams.ContainsKey($property))) {
                            Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                            $ChangedParams.Add($property, $PSBoundParameters[$property])
                        }
                    }
                }
                else {
                    if (!($ChangedParams.ContainsKey($property))) {
                        Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                        $ChangedParams.Add($property, $PSBoundParameters[$property])
                    }
                }
            }
        }

        $ChangedParams.Remove('StoreName')
        Write-Verbose -Message $localizedData.CallingSetSTFWebReceiverResourcesService
        Set-STFWebReceiverResourcesService @ChangedParams

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

        [Parameter()]
		[System.Boolean]
		$PersistentIconCacheEnabled,

        [Parameter()]
		[System.UInt32]
		$IcaFileCacheExpiry,

        [Parameter()]
		[System.UInt32]
		$IconSize,

        [Parameter()]
		[System.Boolean]
		$ShowDesktopViewer
	)
    process {

        $targetResource = Get-TargetResource -StoreName $StoreName
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

        if ($inCompliance) {
            Write-Verbose $localizedData.ResourceInDesiredState
        }
        else {
            Write-Verbose $localizedData.ResourceNotInDesiredState
        }

        return $inCompliance;

	} #end process
}


Export-ModuleMember -Function *-TargetResource

