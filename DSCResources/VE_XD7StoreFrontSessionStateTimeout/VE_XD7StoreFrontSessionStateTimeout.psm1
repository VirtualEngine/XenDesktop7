<#	
    ===========================================================================
     Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
     Created on:   	2/8/2019 12:12 PM
     Created by:   	CERBDM
     Organization: 	Cerner Corporation
     Filename:     	VE_XD7StoreFrontSessionStateTimeout.psm1
    -------------------------------------------------------------------------
     Module Name: VE_XD7StoreFrontSessionStateTimeout
    ===========================================================================
#>

Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontSessionStateTimeout.Resources.psd1;

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [System.UInt32]
        $IntervalInMinutes,

        [System.UInt32]
        $CommunicationAttempts,

        [System.UInt32]
        $CommunicationTimeout,

        [System.UInt32]
        $LoginFormTimeout
    )

    begin {
        AssertXDModule -Name 'UtilsModule','WebReceiverModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
    }
    process {
        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false
        Import-Module (FindXDModule -Name 'WebReceiverModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false
        Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false

        try {
            Write-Verbose "Calling Get-STFStoreService for $StoreName"
            $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
            Write-Verbose "Calling Get-DSWebReceiversSummary"
            $Configuration = Get-DSWebReceiversSummary | Where-object {$_.StoreVirtualPath -eq ($StoreService.VirtualPath)}
        }
        catch {
            Write-Verbose "Trapped error getting web receiver communication. Error: $($Error[0].Exception.Message)"
        }
        $returnValue = @{
            StoreName = [System.String]$StoreName
            IntervalInMinutes = [System.UInt32]$Configuration.SessionStateTimeout
            CommunicationAttempts = [System.UInt32]$Configuration.CommunicationAttempts
            CommunicationTimeout = [System.UInt32]$Configuration.CommunicationTimeout.TotalMinutes
            LoginFormTimeout = [System.UInt32]$Configuration.LoginFormTimeout
        }

        $returnValue
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [System.UInt32]
        $IntervalInMinutes,

        [System.UInt32]
        $CommunicationAttempts,

        [System.UInt32]
        $CommunicationTimeout,

        [System.UInt32]
        $LoginFormTimeout
    )

    begin {
        AssertXDModule -Name 'UtilsModule','WebReceiverModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
    }
    process {
        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false
        Import-Module (FindXDModule -Name 'WebReceiverModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false
        Import-module Citrix.StoreFront -ErrorAction Stop -Verbose:$false

        try {
            Write-Verbose "Calling Get-STFStoreService for $StoreName"
            $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
            Write-Verbose "Calling Get-STFWebReceiverService"
            $webreceiverservice = Get-STFWebReceiverService -StoreService $Storeservice
            Write-Verbose "Calling Get-DSWebReceiversSummary"
            $Configuration = Get-DSWebReceiversSummary | Where-object {$_.StoreVirtualPath -eq ($StoreService.VirtualPath)}
        }
        catch {
            Write-Verbose "Trapped error getting web receiver user interface. Error: $($Error[0].Exception.Message)"
        }

        $ChangedParams = @{
            SiteId = $StoreService.SiteId
            VirtualPath = $webreceiverservice.VirtualPath
        }
        $targetResource = Get-TargetResource @PSBoundParameters;
        foreach ($property in $PSBoundParameters.Keys) {
            if ($targetResource.ContainsKey($property)) {
                $expected = $PSBoundParameters[$property];
                $actual = $targetResource[$property];
                if ($PSBoundParameters[$property] -is [System.String[]]) {
                    if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                        if (!($ChangedParams.ContainsKey($property))) {
                            Write-Verbose "Adding $property to ChangedParams"
                            $ChangedParams.Add($property,$PSBoundParameters[$property])
                        }
                    }
                }
                elseif ($expected -ne $actual) {
                    if (!($ChangedParams.ContainsKey($property))) {
                        Write-Verbose "Adding $property to ChangedParams"
                        $ChangedParams.Add($property,$PSBoundParameters[$property])
                    }
                }
            }
        }

        #Add in parameters that aren't changed with their current values
        If (!($ChangedParams.ContainsKey("IntervalInMinutes"))) {
            Write-Verbose "Adding IntervalInMinutes to ChangedParams with current value"
            $ChangedParams.Add("IntervalInMinutes",[System.UInt32]$Configuration.SessionStateTimeout)
        }
        If (!($ChangedParams.ContainsKey("CommunicationAttempts"))) {
            Write-Verbose "Adding CommunicationAttempts to ChangedParams with current value"
            $ChangedParams.Add("CommunicationAttempts",[System.UInt32]$Configuration.CommunicationAttempts)
        }
        If (!($ChangedParams.ContainsKey("CommunicationTimeout"))) {
            Write-Verbose "Adding CommunicationTimeout to ChangedParams with current value"
            $ChangedParams.Add("CommunicationTimeout",[System.UInt32]$Configuration.CommunicationTimeout.TotalMinutes)
        }
        If (!($ChangedParams.ContainsKey("LoginFormTimeout"))) {
            Write-Verbose "Adding LoginFormTimeout to ChangedParams with current value"
            $ChangedParams.Add("LoginFormTimeout",[System.UInt32]$Configuration.LoginFormTimeout)
        }
        
        $ChangedParams.Remove('StoreName')
        Write-Verbose "Calling Set-DSSessionStateTimeout"
        Set-DSSessionStateTimeout @ChangedParams
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
        $StoreName,

        [System.UInt32]
        $IntervalInMinutes,

        [System.UInt32]
        $CommunicationAttempts,

        [System.UInt32]
        $CommunicationTimeout,

        [System.UInt32]
        $LoginFormTimeout
    )

    $targetResource = Get-TargetResource @PSBoundParameters;
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

Export-ModuleMember -Function *-TargetResource;

