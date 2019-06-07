<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization:
	 Filename:     	VE_XD7StoreFrontRoamingGateway.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontRoamingGateway
	===========================================================================
#>


Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontRoamingGateway.Resources.psd1;

function Get-TargetResource
{
	[CmdletBinding()]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[Parameter(Mandatory = $true)]
		[ValidateSet('UsedForHDXOnly','Domain','RSA','DomainAndRSA','SMS','GatewayKnows','SmartCard','None')]
		[System.String]
		$LogonType,

		[System.String]
		$SmartCardFallbackLogonType,

		[System.String]
		$Version,

		[parameter(Mandatory = $true)]
		[System.String]
		$GatewayUrl,

		[System.String]
		$CallbackUrl,

		[System.Boolean]
		$SessionReliability,

		[System.Boolean]
		$RequestTicketTwoSTAs,

		[System.String]
		$SubnetIPAddress,

		[System.String[]]
		$SecureTicketAuthorityUrls,

		[System.Boolean]
		$StasUseLoadBalancing,

		[System.String]
		$StasBypassDuration,

		[System.String]
		$GslbUrl,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

	try {

		Write-Verbose -Message ($localizedData.CallingGetSTFRoamingGateway -f $Name)
		$Gateway = Get-STFRoamingGateway -Name $Name -ErrorAction SilentlyContinue
	}
	catch { }

	$returnValue = @{
		Name = [System.String]$Gateway.Name
		LogonType = [System.String]$Gateway.Logon
		SmartCardFallbackLogonType = [System.String]$Gateway.SmartCardFallback
		Version = [System.String]$Gateway.Version
		GatewayUrl = [System.String]$Gateway.Location
		CallbackUrl = [System.String]$Gateway.CallbackUrl
		SessionReliability = [System.Boolean]$Gateway.SessionReliability
		RequestTicketTwoSTAs = [System.Boolean]$Gateway.RequestTicketTwoStas
		SubnetIPAddress = [System.String]$Gateway.IpAddress
		SecureTicketAuthorityUrls = [System.String[]]$Gateway.SecureTicketAuthorityUrls
		StasUseLoadBalancing = [System.Boolean]$Gateway.StasUseLoadBalancing
		StasBypassDuration = [System.String]$Gateway.StasBypassDuration
		GslbUrl = [System.String]$Gateway.GslbLocation
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[Parameter(Mandatory = $true)]
		[ValidateSet('UsedForHDXOnly','Domain','RSA','DomainAndRSA','SMS','GatewayKnows','SmartCard','None')]
		[System.String]
		$LogonType,

		[Parameter(Mandatory = $true)]
		[System.String]
		$GatewayUrl,

		[Parameter()]
		[System.String]
		$SmartCardFallbackLogonType,

		[Parameter()]
		[System.String]
		$Version,

		[Parameter()]
		[System.String]
		$CallbackUrl,

		[Parameter()]
		[System.Boolean]
		$SessionReliability,

		[Parameter()]
		[System.Boolean]
		$RequestTicketTwoSTAs,

		[Parameter()]
		[System.String]
		$SubnetIPAddress,

		[Parameter()]
		[System.String[]]
		$SecureTicketAuthorityUrls,

		[Parameter()]
		[System.Boolean]
		$StasUseLoadBalancing,

		[Parameter()]
		[System.String]
		$StasBypassDuration,

		[Parameter()]
		[System.String]
		$GslbUrl,

		[Parameter()]
		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)

	if (!$GatewayUrl.EndsWith('/')) { $PSBoundParameters['GatewayUrl'] = '{0}/' -f $GatewayUrl }
	Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;
	$Gateway = Get-STFRoamingGateway -Name $Name -ErrorAction SilentlyContinue

	if ($Ensure -eq 'Present') {
		#Region Create Params hashtable
		$AllParams = @{}
		$ChangedParams = @{
			Name = $Name
			LogonType = $LogonType
			GatewayUrl = $GatewayUrl
		}
		$targetResource = Get-TargetResource -Name $Name -LogonType $LogonType -GatewayUrl $GatewayUrl;
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
					else {
						Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
						$ChangedParams.Add($property,$PSBoundParameters[$property])
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
		#endregion

		if ($Gateway) {
			#Set changed parameters
			Write-Verbose -Message $localizedData.CallingSetSTFRoamingGateway
			Set-STFRoamingGateway @ChangedParams -confirm:$false
		}
		else {
			#Create gateway
			Write-Verbose -Message $localizedData.CallingAddSTFRoamingGateway
			Add-STFRoamingGateway @AllParams -confirm:$false
		}

	}
	else {
		#Uninstall
		$Gateway | Remove-STFRoamingGateway -confirm:$false
	}

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[Parameter(Mandatory = $true)]
		[ValidateSet('UsedForHDXOnly','Domain','RSA','DomainAndRSA','SMS','GatewayKnows','SmartCard','None')]
		[System.String]
		$LogonType,

		[Parameter(Mandatory = $true)]
		[System.String]
		$GatewayUrl,

		[Parameter()]
		[System.String]
		$SmartCardFallbackLogonType,

		[Parameter()]
		[System.String]
		$Version,

		[Parameter()]
		[System.String]
		$CallbackUrl,

		[Parameter()]
		[System.Boolean]
		$SessionReliability,

		[Parameter()]
		[System.Boolean]
		$RequestTicketTwoSTAs,

		[Parameter()]
		[System.String]
		$SubnetIPAddress,

		[Parameter()]
		[System.String[]]
		$SecureTicketAuthorityUrls,

		[Parameter()]
		[System.Boolean]
		$StasUseLoadBalancing,

		[Parameter()]
		[System.String]
		$StasBypassDuration,

		[Parameter()]
		[System.String]
		$GslbUrl,

		[Parameter()]
		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)

	if (!$GatewayUrl.EndsWith('/')) { $PSBoundParameters['GatewayUrl'] = '{0}/' -f $GatewayUrl }
	$targetResource = Get-TargetResource -Name $Name -LogonType $LogonType -GatewayUrl $GatewayUrl
	if ($Ensure -eq 'Present') {
		$inCompliance = $true;
		foreach ($property in $PSBoundParameters.Keys) {
			if ($targetResource.ContainsKey($property)) {
				$expected = $PSBoundParameters[$property];
				$actual = $targetResource[$property];
				if ($PSBoundParameters[$property] -is [System.String[]]) {
					if ($actual) {
						if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
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
		if ($targetResource.Name -eq $Name) {
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
