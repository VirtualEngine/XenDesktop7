<#
    ===========================================================================
     Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
     Created on:   	2/8/2019 12:12 PM
     Created by:   	CERBDM
     Organization: 	Cerner Corporation
     Filename:     	VE_VE_XD7StoreFrontOptimalGateway.psm1
    -------------------------------------------------------------------------
     Module Name: VE_VE_XD7StoreFrontOptimalGateway
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
        [parameter()]
        [System.UInt64]
        $SiteId=1,

        [parameter(Mandatory = $true)]
        [System.String]
        $ResourcesVirtualPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $GatewayName,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Hostnames,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $StaUrls,

        [parameter()]
        [System.Boolean]
        $StasUseLoadBalancing,

        [parameter()]
        [System.String]
        $StasBypassDuration,

        [parameter()]
        [System.Boolean]
        $EnableSessionReliability,

        [parameter()]
        [System.Boolean]
        $UseTwoTickets,

        [parameter()]
        [System.String[]]
        $Farms,

        [parameter()]
        [System.String[]]
        $Zones,

        [parameter()]
        [System.Boolean]
        $EnabledOnDirectAccess,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
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
            Write-Verbose "Running Get-DSOptimalGatewayForFarms"
            $Gateway = Get-DSOptimalGatewayForFarms -SiteId $SiteId -ResourcesVirtualPath $ResourcesVirtualPath -ErrorAction SilentlyContinue
        }
        catch {
            Write-Verbose "Error on Get-DSOptimalGatewayForFarms: $($Error[0].Exception.Message)"
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
    param
    (
        [parameter()]
        [System.UInt64]
        $SiteId=1,

        [parameter(Mandatory = $true)]
        [System.String]
        $ResourcesVirtualPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $GatewayName,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Hostnames,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $StaUrls,

        [parameter()]
        [System.Boolean]
        $StasUseLoadBalancing,

        [parameter()]
        [System.String]
        $StasBypassDuration,

        [parameter()]
        [System.Boolean]
        $EnableSessionReliability,

        [parameter()]
        [System.Boolean]
        $UseTwoTickets,

        [parameter()]
        [System.String[]]
        $Farms,

        [parameter()]
        [System.String[]]
        $Zones,

        [parameter()]
        [System.Boolean]
        $EnabledOnDirectAccess,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
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

        Write-Verbose "Running Get-DSOptimalGatewayForFarms"
        Try {
            $Gateway = Get-DSOptimalGatewayForFarms -SiteId $SiteId -ResourcesVirtualPath $ResourcesVirtualPath -ErrorAction SilentlyContinue
        }
        Catch {
            Write-Verbose "Error on Get-DSOptimalGatewayForFarms: $($Error[0].Exception.Message)"
        }

        If (!($Farms)) {
            try {
                Write-Verbose "Running Get-DSFarmSets"
                $Farms = get-dsfarmsets -IISSiteId $siteid -virtualpath $resourcesVirtualPath | Select-Object -expandproperty Farms | Select-Object -expandproperty FarmName
            }
            catch {
                Write-Verbose "Error on Get-DSFarmSets: $($Error[0].Exception.Message)"
            }
        }

        If ($Ensure -eq "Present") {
            #Region Create Params hashtable
            #  Added all params since powershell command replaces all current values if you set anything
            If (!($PSBoundParameters.ContainsKey("StaUrls"))) {
                $StaUrls = [System.String[]]$Gateway.StaUrls
                Write-Verbose "Setting StaUrls to current value: $StaUrls"
            }
            Else {
                Write-Verbose "StaUrls changed to: $StaUrls"
            }
            If (!($PSBoundParameters.ContainsKey("StasUseLoadBalancing"))) {
                $StasUseLoadBalancing = [System.Boolean]$Gateway.StasUseLoadBalancing
                Write-Verbose "Setting StasUseLoadBalancing to current value: $StasUseLoadBalancing"
            }
            Else {
                Write-Verbose "StasUseLoadBalancing changed to: $StasUseLoadBalancing"
            }
            If (!($PSBoundParameters.ContainsKey("StasBypassDuration"))) {
                $StasBypassDuration = [System.String]$Gateway.StasBypassDuration
                Write-Verbose "Setting StasBypassDuration to current value: $StasBypassDuration"
            }
            Else {
                Write-Verbose "StasBypassDuration changed to: $StasBypassDuration"
            }
            If (!($PSBoundParameters.ContainsKey("EnableSessionReliability"))) {
                $EnableSessionReliability = [System.Boolean]$Gateway.EnableSessionReliability
                Write-Verbose "Setting EnableSessionReliability to current value: $EnableSessionReliability"
            }
            Else {
                Write-Verbose "EnableSessionReliability changed to: $EnableSessionReliability"
            }
            If (!($PSBoundParameters.ContainsKey("UseTwoTickets"))) {
                $UseTwoTickets = [System.Boolean]$Gateway.UseTwoTickets
                Write-Verbose "Setting UseTwoTickets to current value: $UseTwoTickets"
            }
            Else {
                Write-Verbose "UseTwoTickets changed to: $UseTwoTickets"
            }
            If (!($PSBoundParameters.ContainsKey("Zones"))) {
                $Zones = [System.String[]]$Gateway.Zones
                Write-Verbose "Setting Zones to current value: $Zones"
            }
            Else {
                Write-Verbose "Zones changed to: $Zones"
            }
            If (!($PSBoundParameters.ContainsKey("EnabledOnDirectAccess"))) {
                $EnabledOnDirectAccess = [System.Boolean]$Gateway.EnabledOnDirectAccess
                Write-Verbose "Setting EnabledOnDirectAccess to current value: $EnabledOnDirectAccess"
            }
            Else {
                Write-Verbose "EnabledOnDirectAccess changed to: $EnabledOnDirectAccess"
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
            Write-Verbose "Calling Set-DSOptimalGatewayForFarms"
            Set-DSOptimalGatewayForFarms @ChangedParams

        }
        Else {
            #Uninstall
            Write-Verbose "Calling Remove-DSOptimalGatewayForFarms"
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
        [parameter()]
        [System.UInt64]
        $SiteId=1,

        [parameter(Mandatory = $true)]
        [System.String]
        $ResourcesVirtualPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $GatewayName,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Hostnames,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $StaUrls,

        [parameter()]
        [System.Boolean]
        $StasUseLoadBalancing,

        [parameter()]
        [System.String]
        $StasBypassDuration,

        [parameter()]
        [System.Boolean]
        $EnableSessionReliability,

        [parameter()]
        [System.Boolean]
        $UseTwoTickets,

        [parameter()]
        [System.String[]]
        $Farms,

        [parameter()]
        [System.String[]]
        $Zones,

        [parameter()]
        [System.Boolean]
        $EnabledOnDirectAccess,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

        $targetResource = Get-TargetResource @PSBoundParameters;
        If ($Ensure -eq 'Present') {
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
        Else {
            If ($targetResource.GatewayName -eq $GatewayName) {
                $inCompliance = $false
            }
            Else {
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

