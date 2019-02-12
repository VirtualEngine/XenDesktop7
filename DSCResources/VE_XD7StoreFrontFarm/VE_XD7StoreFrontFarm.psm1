<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2/8/2019 12:12 PM
	 Created by:   	CERBDM
	 Organization: 	
	 Filename:     	VE_XD7StoreFrontFarm.psm1
	-------------------------------------------------------------------------
	 Module Name: VE_XD7StoreFrontFarm
	===========================================================================
#>


Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontFarm.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $FarmName,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Port,

        [parameter(Mandatory = $true)]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $LoadBalance,

        [parameter(Mandatory = $true)]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType
    )
    begin {

        #AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {

        Import-module Citrix.StoreFront -ErrorAction Stop;
        
        try {
            $StoreService = Get-STFStoreService | Where-object {$_.name -eq $SiteName}
            $StoreFarm = Get-STFStoreFarm -StoreService $StoreService
        }
        catch { }

        switch ($StoreFarm.service.Anonymous) {
            $True {$CurrentAuthType = "Anonymous"}
            $False {$CurrentAuthType = "Explicit"}
        }

        $targetResource = @{
            SiteName = $StoreService.Name
            FarmName = $StoreFarm.FarmName
            port = $StoreFarm.Port
            transportType = $StoreFarm.TransportType
            servers = $StoreFarm.Servers
            LoadBalance = $StoreFarm.LoadBalance
            farmType = $StoreFarm.FarmType
            AuthType = $CurrentAuthType
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
        $FarmName,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Port,

        [parameter(Mandatory = $true)]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $LoadBalance,

        [parameter(Mandatory = $true)]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType   #,

        #[ValidateSet("Present","Absent")]
        #[System.String]
        #$Ensure

    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;
            $inCompliance = $true;
            foreach ($property in $PSBoundParameters.Keys) {

                if ($targetResource.ContainsKey($property)) {

                    $expected = $PSBoundParameters[$property];
                    $actual = $targetResource[$property];
                    if ($PSBoundParameters[$property] -is [System.String[]]) {

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
        $FarmName,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Port,

        [parameter(Mandatory = $true)]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [System.String]
        $TransportType,

        [parameter(Mandatory = $true)]
        [System.String]
        $Servers,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $LoadBalance,

        [parameter(Mandatory = $true)]
        [ValidateSet("XenApp","XenDesktop","AppController")]
        [System.String]
        $FarmType,

        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType   #,

        #[ValidateSet("Present","Absent")]
        #[System.String]
        #$Ensure

    )
    begin {

        #AssertXDModule -Name 'Citrix.StoreFront';

    }
    process {
        Import-module Citrix.StoreFront -ErrorAction Stop
        add-pssnapin Citrix.DeliveryServices.Web.Commands -ErrorAction Stop
        add-pssnapin Citrix.DeliveryServices.Framework.Commands -ErrorAction Stop

        $dsInstallProp = Get-ItemProperty -Path HKLM:\SOFTWARE\Citrix\DeliveryServicesManagement -Name InstallDir
        $dsInstallDir = $dsInstallProp.InstallDir
        $modules = Get-ChildItem -Path "$dsInstallDir\Cmdlets" | Where-Object {$_.Name -like "*.psm1"} | Select-Object -ExpandProperty FullName
        foreach ($dsModule in $modules) {
            Import-Module $dsModule -Scope Global
        }

        $DefSite = Get-Website | Where-Object { $_.name -eq "Default Web Site" }
        $SiteID = $DefSite.Id
        $StoreVirtPath = "/Citrix/$($SiteName)"
        $Controller = Get-DSFrameworkController
        $TenantID = $Controller.DefaultTenant.Id
        $Servers = $Servers.Split(",")

        $SetStoreFarmParams = @{
            StoreService = Get-STFStoreService | Where-object {$_.name -eq $SiteName};
            FarmName = $FarmName
            Port = $port
            TransportType = $transportType
            Servers = $servers
            LoadBalance = $LoadBalance
            FarmType = $farmType
        }

        $NewStoreFarmParams = @{
            SiteID = $SiteID
            VirtualPath = $StoreVirtPath
            FarmName = $FarmName
            servicePort = $port
            transportType = $transportType
            Servers = $servers
            LoadBalance = $LoadBalance
            FarmType = $farmType
            friendlyName = $SiteName
            tenantId = $TenantID.GUID
        }

        If ($AuthType -eq "Explicit") {
            $AuthSite = (Get-DSWebSite).applications | Where-Object { $_.name -eq 'Authentication' }
            $AuthVirtPath = $AuthSite.VirtualPath
            $AuthSummary = Get-DSAuthenticationServiceSummary -SiteId $SiteID -VirtualPath $AuthVirtPath
        }

        If (Get-STFStoreService | Where-Object {$_.name -eq $SiteName}) {
            #TODO: how to check to see if AuthType was wrong
            If ($AuthType -eq "Explicit") {
                Set-STFStoreService -AuthenticationService $AuthSummary
                #Not sure if need to reset this or not.  doing just in case
                $SetStoreFarmParams["StoreService"] = Get-STFStoreService | Where-object {$_.name -eq $SiteName}
            }
            Else {
                #TODO: What to put if anonymous
            }
            Set-STFStoreFarm @SetStoreFarmParams | Out-Null
        }
        Else {
            If ($AuthType -eq "Explicit") {
                $NewStoreFarmParams.Add("authSummary",$AuthSummary)
                Install-DSStoreServiceAndConfigure @NewStoreFarmParams | Out-Null
            }
            Else {
                Install-DSAnonymousStoreService @NewStoreFarmParams | Out-Null
            }
        }

    } #end process
} #end function Set-TargetResource

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
#Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;

