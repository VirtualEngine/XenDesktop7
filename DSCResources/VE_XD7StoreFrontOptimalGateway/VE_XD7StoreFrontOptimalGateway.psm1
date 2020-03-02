<#
    ===========================================================================
     Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
     Created on:   	2/8/2019 12:12 PM
     Created by:   	CERBDM
     Organization: 	Cerner Corporation
     Filename:     	VE_XD7StoreFrontOptimalGateway.psm1
    -------------------------------------------------------------------------
     Module Name: VE_XD7StoreFrontOptimalGateway
    ===========================================================================
#>

#   Set-DSOptimalGatewayForFarms

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontOptimalGateway.Resources.psd1;

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourcesVirtualPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GatewayName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Hostnames,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StaUrls
    )
    begin {

        AssertXDModule -Name 'StoresModule','UtilsModule','FarmsModule','RoamingRecordsModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
    }
    process {
        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'StoresModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'FarmsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'RoamingRecordsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1

        try {

            Write-Verbose -Message $localizedData.CallingGetDSOptimalGatewayForFarms
            $Gateway = Get-DSOptimalGatewayForFarms -SiteId $SiteId -ResourcesVirtualPath $ResourcesVirtualPath -ErrorAction SilentlyContinue
        }
        catch {

            Write-Verbose -Message ($localizedData.TrappedError -f 'getting gateways', $Error[0].Exception.Message)
        }

        $returnValue = @{
            SiteId = [System.UInt64]$Gateway.SiteId
            ResourcesVirtualPath = [System.String]$Gateway.ResourcesVirtualPath
            GatewayName = [System.String]$Gateway.GatewayName
            Hostnames = [System.String[]]$Gateway.Hostnames.hostname
            StaUrls = [System.String[]]$Gateway.StaUrls
            StasUseLoadBalancing = [System.Boolean]$Gateway.StasUseLoadBalancing
            StasBypassDuration = [System.String]$Gateway.StasBypassDuration
            EnableSessionReliability = [System.Boolean]$Gateway.EnableSessionReliability
            UseTwoTickets = [System.Boolean]$Gateway.UseTwoTickets
            Farms = [System.String[]]$Gateway.Farms
            Zones = [System.String[]]$Gateway.Zones
            EnabledOnDirectAccess = [System.Boolean]$Gateway.EnabledOnDirectAccess
        }
        $returnValue
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourcesVirtualPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GatewayName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Hostnames,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StaUrls,

        [Parameter()]
        [System.Boolean]
        $StasUseLoadBalancing,

        [Parameter()]
        [System.String]
        $StasBypassDuration,

        [Parameter()]
        [System.Boolean]
        $EnableSessionReliability,

        [Parameter()]
        [System.Boolean]
        $UseTwoTickets,

        [Parameter()]
        [System.String[]]
        $Farms,

        [Parameter()]
        [System.String[]]
        $Zones,

        [Parameter()]
        [System.Boolean]
        $EnabledOnDirectAccess,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    begin {

        AssertXDModule -Name 'UtilsModule','StoresModule','FarmsModule','RoamingRecordsModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
    }
    process {

        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'StoresModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'FarmsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'RoamingRecordsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1

        try {

            Write-Verbose -Message $localizedData.CallingGetDSOptimalGatewayForFarms
            $Gateway = Get-DSOptimalGatewayForFarms -SiteId $SiteId -ResourcesVirtualPath $ResourcesVirtualPath -ErrorAction SilentlyContinue
        }
        catch {

            Write-Verbose -Message ($localizedData.TrappedError -f 'Get-DSOptimalGatewayForFarms', $Error[0].Exception.Message)
        }

        if (!($Farms)) {
            try {

                Write-Verbose -Message $localizedData.CallingGetDSFarmSets
                $Farms = Get-DSFarmSets -IISSiteId $siteid -virtualpath $resourcesVirtualPath | Select-Object -expandproperty Farms | Select-Object -expandproperty FarmName
            }
            catch {

                Write-Verbose -Message ($localizedData.TrappedError -f 'Get-DSFarmSets', $Error[0].Exception.Message)
            }
        }

        if ($Ensure -eq 'Present') {
            #Region Create Params hashtable
            #  Added all params since powershell command replaces all current values if you set anything
            if (!($PSBoundParameters.ContainsKey('StaUrls'))) {
                $StaUrls = [System.String[]]$Gateway.StaUrls
                Write-Verbose -Message ($localizedData.SettingStaUrls -f $StaUrls)
            }
            else {
                Write-Verbose -Message ($localizedData.UpdatingStaUrls -f $StaUrls)
            }
            if (!($PSBoundParameters.ContainsKey('StasUseLoadBalancing'))) {
                $StasUseLoadBalancing = [System.Boolean]$Gateway.StasUseLoadBalancing
                Write-Verbose -Message ($localizedData.SettingStaLoadBalancing -f $StasUseLoadBalancing)
            }
            else {
                Write-Verbose -Message ($localizedData.UpdatingStaLoadBalancing -f $StasUseLoadBalancing)
            }
            if (!($PSBoundParameters.ContainsKey('StasBypassDuration'))) {
                $StasBypassDuration = [System.String]$Gateway.StasBypassDuration
                Write-Verbose -Message ($localizedData.SettingStaBypassDuration -f $StasBypassDuration)
            }
            else {
                Write-Verbose -Message ($localizedData.UpdatingStaBypassDuration -f $StasBypassDuration)
            }
            if (!($PSBoundParameters.ContainsKey('EnableSessionReliability'))) {
                $EnableSessionReliability = [System.Boolean]$Gateway.EnableSessionReliability
                Write-Verbose -Message ($localizedData.SettingSessionReliability -f $EnableSessionReliability)
            }
            else {
                Write-Verbose -Message ($localizedData.UpdatingSessionReliability -f $EnableSessionReliability)
            }
            if (!($PSBoundParameters.ContainsKey('UseTwoTickets'))) {
                $UseTwoTickets = [System.Boolean]$Gateway.UseTwoTickets
                Write-Verbose -Message ($localizedData.SettingRequireTwoTickets -f $UseTwoTickets)
            }
            else {
                Write-Verbose -Message ($localizedData.UpdatingRequireTwoTickets -f $UseTwoTickets)
            }
            if (!($PSBoundParameters.ContainsKey('Zones'))) {
                $Zones = [System.String[]]$Gateway.Zones
                Write-Verbose -Message ($localizedData.SettingZones -f ($Zones -join ','))
            }
            else {
                Write-Verbose -Message ($localizedData.UpdatingZones -f ($Zones -join ','))
            }
            if (!($PSBoundParameters.ContainsKey('EnabledOnDirectAccess'))) {
                $EnabledOnDirectAccess = [System.Boolean]$Gateway.EnabledOnDirectAccess
                Write-Verbose -Message ($localizedData.SettingEnabledOnDirectAccess -f $EnabledOnDirectAccess)
            }
            else {
                Write-Verbose -Message ($localizedData.UpdaingEnabledOnDirectAccess -f $EnabledOnDirectAccess)
            }

            $ChangedParams = @{
                SiteId = $SiteId
                ResourcesVirtualPath = $ResourcesVirtualPath
                GatewayName = $GatewayName
                Hostnames = $Hostnames
                StaUrls = $StaUrls
                StasUseLoadBalancing = $StasUseLoadBalancing
                StasBypassDuration = $StasBypassDuration
                EnableSessionReliability = $EnableSessionReliability
                UseTwoTickets = $UseTwoTickets
                Farms = $Farms
                Zones = $Zones
                EnabledOnDirectAccess = $EnabledOnDirectAccess
            }
            #endregion

            #Create gateway
            Write-Verbose -Message $localizedData.CallingSetDSOptimalGatewayForFarms
            Set-DSOptimalGatewayForFarms @ChangedParams

        }
        Else {
            #Uninstall
            Write-Verbose -Message $localizedData.CallingRemoveDSOptimalGatewayForFarms
            Remove-DSOptimalGatewayForFarms -SiteId $SiteId -ResourcesVirtualPath $ResourcesVirtualPath
        }
        #Include this line if the resource requires a system reboot.
        #$global:DSCMachineStatus = 1
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourcesVirtualPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GatewayName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Hostnames,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StaUrls,

        [Parameter()]
        [System.Boolean]
        $StasUseLoadBalancing,

        [Parameter()]
        [System.String]
        $StasBypassDuration,

        [Parameter()]
        [System.Boolean]
        $EnableSessionReliability,

        [Parameter()]
        [System.Boolean]
        $UseTwoTickets,

        [Parameter()]
        [System.String[]]
        $Farms,

        [Parameter()]
        [System.String[]]
        $Zones,

        [Parameter()]
        [System.Boolean]
        $EnabledOnDirectAccess,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $targetResource = Get-TargetResource -ResourcesVirtualPath $ResourcesVirtualPath -GatewayName $GatewayName -Hostnames $Hostnames -StaUrls $StaUrls
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


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource

