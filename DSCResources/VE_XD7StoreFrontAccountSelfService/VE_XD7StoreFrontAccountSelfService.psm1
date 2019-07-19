<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	5/21/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization:
	 Filename:     	VE_XD7StoreFrontAccountSelfService.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontAccountSelfService
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontAccountSelfService.Resources.psd1;
function Get-TargetResource
{
	[CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$StoreName
	)
    process {

		Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;
		Import-Module Citrix.StoreFront.Authentication.PasswordManager -ErrorAction Stop -Verbose:$false

		Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName };
        if ($StoreService) {
            ## This is a hack, as Get-STFStoreFarm throws an error if run twice in quick succession?!
            $null = Get-STFStoreFarm -StoreService $StoreService -Verbose -OutVariable StoreFarm
            $AuthVirtualPath = $StoreService.AuthenticationServiceVirtualPath
            $SiteId = $StoreService.SiteId
			Write-Verbose -Message ($localizedData.CallingGetSTFAuthenticationService -f $AuthVirtualPath,$SiteId)
			$AuthenticationService = Get-STFAuthenticationService -VirtualPath $AuthVirtualPath -SiteId $SiteId
			Write-Verbose -Message $localizedData.CallingGetSTFAccountSelfService
			$AccountSelfService = Get-STFAccountSelfService -AuthenticationService $AuthenticationService
			Write-Verbose -Message $localizedData.CallingGetSTFPasswordManagerAccountSelfService
			$PasswordManagerServiceUrl = Get-STFPasswordManagerAccountSelfService -AuthenticationService $AuthenticationService
		}

        $targetResource = @{
			StoreName = [System.String]$StoreName
			AllowResetPassword = [System.Boolean]$AccountSelfService.AllowResetPassword
			AllowUnlockAccount = [System.Boolean]$AccountSelfService.AllowUnlockAccount
			PasswordManagerServiceUrl = [System.String]$PasswordManagerServiceUrl
		};

        return $targetResource;

    } #end process

}


function Set-TargetResource
{
	[CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$StoreName,

        [Parameter()]
		[System.Boolean]
		$AllowResetPassword,

        [Parameter()]
		[System.Boolean]
		$AllowUnlockAccount,

        [Parameter()]
		[System.String]
		$PasswordManagerServiceUrl
	)
    process {

        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
		Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName };
        if ($StoreService) {
            ## This is a hack, as Get-STFStoreFarm throws an error if run twice in quick succession?!
            $null = Get-STFStoreFarm -StoreService $StoreService -Verbose -OutVariable StoreFarm
            $AuthVirtualPath = $StoreService.AuthenticationServiceVirtualPath
            $SiteId = $StoreService.SiteId
			Write-Verbose -Message ($localizedData.CallingGetSTFAuthenticationService -f $AuthVirtualPath,$SiteId)
			$AuthenticationService = Get-STFAuthenticationService -VirtualPath $AuthVirtualPath -SiteId $SiteId
		}

        $ChangedParams = @{
            AuthenticationService = $AuthenticationService
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

		if ($ChangedParams.ContainsKey('PasswordManagerServiceUrl')) {
			$ChangedParams.Remove('PasswordManagerServiceUrl')
			Write-Verbose -Message $localizedData.CallingSetSTFPasswordManagerAccountSelfService
			Set-STFPasswordManagerAccountSelfService -AuthenticationService $AuthenticationService -PasswordManagerServiceUrl $PasswordManagerServiceUrl
		}
        $ChangedParams.Remove('StoreName')
        Write-Verbose -Message $localizedData.CallingSetSTFAccountSelfService
        Set-STFAccountSelfService @ChangedParams

    } #end process
}


function Test-TargetResource
{
	[CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$StoreName,

        [Parameter()]
		[System.Boolean]
		$AllowResetPassword,

        [Parameter()]
		[System.Boolean]
		$AllowUnlockAccount,

        [Parameter()]
		[System.String]
		$PasswordManagerServiceUrl
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

