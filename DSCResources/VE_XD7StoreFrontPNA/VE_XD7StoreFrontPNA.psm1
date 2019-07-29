<#
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	5/21/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization:
	 Filename:     	VE_XD7StoreFrontPNA.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontPNA
	===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontPNA.Resources.psd1;
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]
		$StoreName
	)

    process {

		Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;
		Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
		$StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName };
		Write-Verbose -Message $localizedData.CallingGetSTFStorePna
		$StorePNA = Get-STFStorePna -StoreService $StoreService

        $targetResource = @{
			StoreName = [System.String]$StoreName
			DefaultPnaService = [System.Boolean]$StorePNA.DefaultPnaService
			Enabled = [System.Boolean]$StorePNA.PnaEnabled
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
		[Parameter(Mandatory = $true)]
		[System.String]
		$StoreName,

        [Parameter()]
		[System.Boolean]
		$DefaultPnaService,

        [Parameter()]
		[ValidateSet('Absent','Present')]
		[System.String]
        $Ensure = 'Present'
	)

    process {

        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
		Write-Verbose -Message ($localizedData.CallingGetSTFStoreService -f $StoreName)
        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.friendlyname -eq $StoreName };
		if ($Ensure -eq 'Present') {
			If ($DefaultPnaService -eq $True) {
				Write-Verbose -Message $localizedData.CallingEnableSTFStorePna
				Enable-STFStorePna -StoreService $StoreService -DefaultPnaService
			}
			else {
				Write-Verbose -Message $localizedData.CallingEnableSTFStorePna
				Enable-STFStorePna -StoreService $StoreService
			}
		}
		else {
			Write-Verbose -Message $localizedData.CallingDisableSTFStorePna
			Disable-STFStorePna -StoreService $StoreService -confirm:$false
		}

    } #end process

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

        [Parameter()]
		[System.Boolean]
		$DefaultPnaService,

        [Parameter()]
		[ValidateSet('Absent','Present')]
		[System.String]
        $Ensure = 'Present'
	)

    process {

        $targetResource = Get-TargetResource -StoreName $StoreName
        if ($Ensure -eq 'Present') {

            if (($targetResource.Enabled -eq $True) -and ($targetResource.DefaultPnaService -eq $DefaultPnaService)) {
                Write-Verbose -Message ($localizedData.ResourceInDesiredState -f $SiteId)
                return $true
            }
            else {
                Write-Verbose -Message ($localizedData.ResourceNotInDesiredState -f $SiteId)
                return $false
            }
        }
        else {

            if (($targetResource.Enabled -ne $False) -or ($targetResource.DefaultPnaService -ne $DefaultPnaService)) {
                Write-Verbose -Message ($localizedData.ResourceNotInDesiredState -f $SiteId)
                return $false
            }
            else {
                Write-Verbose -Message ($localizedData.ResourceInDesiredState -f $SiteId)
                return $true
            }
        }

	} #end process
}


Export-ModuleMember -Function *-TargetResource

