<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	6/7/2019 7:55 AM
	 Created by:   	CERBDM
	 Organization:
	 Filename:     	VE_XD7StoreFrontAuthenticationService.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontAuthenticationService
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontAuthenticationService.Resources.psd1;

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VirtualPath
	)

	Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
	$Auth = Get-STFAuthenticationService -VirtualPath $VirtualPath

	$returnValue = @{
		VirtualPath = [System.String]$Auth.VirtualPath
		FriendlyName = [System.String]$Auth.FriendlyName
		SiteId = [System.UInt64]$Auth.SiteId
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VirtualPath,

        [Parameter()]
		[System.String]
		$FriendlyName,

        [Parameter()]
		[System.UInt64]
		$SiteId,

        [Parameter()]
		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)

	Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false

	if ($Ensure -eq 'Present') {
		Write-Verbose -Message $localizedData.RunningAddSTFAuthenticationService
		Add-STFAuthenticationService @PSBoundParameters
	}
	else {
		Write-Verbose -Message $localizedData.RunningRemoveSTFAuthenticationService
		Get-STFAuthenticationService @PSBoundParameters | Remove-STFAuthenticationService -confirm:$false
	}

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VirtualPath,

        [Parameter()]
		[System.String]
		$FriendlyName,

        [Parameter()]
		[System.UInt64]
		$SiteId,

        [Parameter()]
		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure
	)

	$targetResource = Get-TargetResource -VirtualPath $VirtualPath
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

}

Export-ModuleMember -Function *-TargetResource
