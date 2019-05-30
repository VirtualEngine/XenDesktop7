<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	Cerner Corporation
	 Filename:     	VE_XD7StoreFrontRegisterStoreGateway.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontRegisterStoreGateway
	===========================================================================
#>


Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontRegisterStoreGateway.Resources.psd1;

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
		[System.String[]]
		$GatewayName,

		[parameter(Mandatory = $true)]
		[ValidateSet('CitrixAGBasic','CitrixAGBasicNoPassword','HttpBasic','Certificate','CitrixFederation','IntegratedWindows','Forms-Saml','ExplicitForms')]
		[System.String[]]
		$AuthenticationProtocol,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$EnableRemoteAccess,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = 'Present'
	)

	Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
	Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
	$StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
	if ($StoreService) {
		Write-Verbose -Message $localizedData.CallingGetSTFAuthenticationService
		$Auth = Get-STFAuthenticationService -VirtualPath ($StoreService.AuthenticationServiceVirtualPath) -SiteID ($StoreService.SiteId)
		$EnabledProtocols = $auth.authentication.ProtocolChoices | Where-Object { $_.Enabled } | Select-object -ExpandProperty Name
	}

	$returnValue = @{
		StoreName = [System.String]$StoreService.name
		GatewayName = [System.String[]]$StoreService.gateways.Name
		AuthenticationProtocol = [System.String[]]$EnabledProtocols
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
		$StoreName,

		[Parameter(Mandatory = $true)]
		[System.String[]]
		$GatewayName,

		[Parameter(Mandatory = $true)]
		[ValidateSet('CitrixAGBasic','CitrixAGBasicNoPassword','HttpBasic','Certificate','CitrixFederation','IntegratedWindows','Forms-Saml','ExplicitForms')]
		[System.String[]]
		$AuthenticationProtocol,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$EnableRemoteAccess,

		[Parameter()]
		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)

	Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
	Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
	$StoreService = Get-STFStoreService | Where-Object { $_.friendlyname -eq $StoreName }
	Write-Verbose -Message ($localizedData.CallingGetSTFRoamingGateway -f $GatewayName)
	$GatewayService = Get-STFRoamingGateway -Name $GatewayName
	Write-Verbose -Message ($localizedData.CallingGetSTFAuthenticationService)
	$Auth = Get-STFAuthenticationService -VirtualPath ($StoreService.AuthenticationServiceVirtualPath) -SiteID ($StoreService.SiteId)

	if ($Ensure -eq 'Present') {
		Write-Verbose -Message ($localizedData.CallingRegisterSTFStoreGateway)
		Register-STFStoreGateway -Gateway $GatewayService -StoreService $StoreService -DefaultGateway
		if ($EnableRemoteAccess -eq $true) {
			foreach ($Name in $GatewayName) {
				Write-Verbose -Message ($localizedData.CallingGetSTFRoamingGateway -f $Name)
				$GatewayService = Get-STFRoamingGateway -Name $Name
				Register-STFStoreGateway -Gateway $GatewayService -StoreService $StoreService -DefaultGateway
			}
		}
		foreach ($Protocol in $Auth.Authentication.ProtocolChoices) {
			if ($AuthenticationProtocol -contains $Protocol.Name) {
				if ($Protocol.Enabled) {
					Write-Verbose -Message ($localizedData.ProtocolEnabled -f $Protocol)
				}
				else {
					Write-Verbose -Message ($localizedData.EnablingProtocol -f $Protocol)
					Enable-STFAuthenticationServiceProtocol -Name $Protocol.Name -AuthenticationService $Auth
				}
			}
			else {
				if ($Protocol.Enabled) {
					Write-Verbose -Message ($localizedData.DisablingProtocol -f $Protocol)
					Disable-STFAuthenticationServiceProtocol -Name $Protocol.Name -AuthenticationService $Auth
				}
				else {
					Write-Verbose -Message ($localizedData.ProtocolDisabled -f $Protocol)
				}
			}
		}
	}
	else {
		Write-Verbose -Message $localizedData.CallingUnegisterSTFStoreGateway
		Unregister-STFStoreGateway -Gateway $GatewayService -StoreService $StoreService
	}
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]
		$StoreName,

		[Parameter(Mandatory = $true)]
		[System.String[]]
		$GatewayName,

		[Parameter(Mandatory = $true)]
		[ValidateSet('CitrixAGBasic','CitrixAGBasicNoPassword','HttpBasic','Certificate','CitrixFederation','IntegratedWindows','Forms-Saml','ExplicitForms')]
		[System.String[]]
		$AuthenticationProtocol,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$EnableRemoteAccess,

		[Parameter()]
		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)

	$targetResource = Get-TargetResource @PSBoundParameters
	if ($Ensure -eq 'Present') {
		$inCompliance = $true;
		foreach ($property in $PSBoundParameters.Keys) {
			if ($targetResource.ContainsKey($property)) {
				$expected = $PSBoundParameters[$property];
				$actual = $targetResource[$property];
				if (($PSBoundParameters[$property] -is [System.String[]]) -and ($actual -ne $null)) {
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
	else {
		if ($targetResource.GatewayName -eq $GatewayName) {
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
