<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	5/21/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization:
	 Filename:     	VE_XD7StoreFrontRoamingBeacon.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontRoamingBeacon
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontRoamingBeacon.Resources.psd1;
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.UInt64]
		$SiteId
	)

    process {

		Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
		Write-Verbose -Message $localizedData.CallingGetSTFRoamingBeacon
		$InternalBeacon = Get-STFRoamingBeacon -Internal
		$ExternalBeacon = Get-STFRoamingBeacon -External
        $targetResource = @{
			SiteId = [System.String]$SiteId
			InternalUri = [System.String]$InternalBeacon
			ExternalUri = [System.string[]]$ExternalBeacon
		}
        return $targetResource;

    } #end process

}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.UInt64]
		$SiteId,

        [Parameter()]
		[System.String]
		$InternalUri,

        [Parameter()]
		[System.String[]]
		$ExternalUri
	)

    process {

        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
        $targetResource = Get-TargetResource -SiteId $SiteId
        $ChangedParams = @{}
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
		if ($ChangedParams.ContainsKey('InternalUri')) {
			Write-Verbose -Message ($localizedData.CallingSetSTFRoamingBeacon -f 'Internal')
			Set-STFRoamingBeacon -Internal $PSBoundParameters['InternalUri'] -Verbose
		}
		if ($ChangedParams.ContainsKey('ExternalUri')) {
			Set-STFRoamingBeacon -External $ExternalUri $PSBoundParameters['ExternalUri'] -Verbose
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
		[System.UInt64]
		$SiteId,

        [Parameter()]
		[System.String]
		$InternalUri,

        [Parameter()]
		[System.String[]]
		$ExternalUri
	)

    process {

        $targetResource = Get-TargetResource -SiteId $SiteId
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

