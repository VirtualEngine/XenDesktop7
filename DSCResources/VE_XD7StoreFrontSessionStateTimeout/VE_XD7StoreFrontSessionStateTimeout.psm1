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
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName
    )
    begin {

        AssertXDModule -Name 'UtilsModule','StoresModule','WebReceiverModule','AuthenticationModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
    }
    process {

        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'StoresModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'WebReceiverModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'AuthenticationModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false

        try {

            Write-Verbose -Message ($localized.CallingGetSTFStoreService -f $StoreName)
            $StoreService = Get-STFStoreService | Where-object { $_.friendlyname -eq $StoreName };
            $Configuration = Get-DSWebReceiversSummary | Where-Object { $_.StoreVirtualPath -eq ($StoreService.VirtualPath) }
        }
        catch {

            Write-Verbose -Message ($localized.TrappedError -f $Error[0].Exception.Message)
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter()]
        [System.UInt32]
        $IntervalInMinutes,

        [Parameter()]
        [System.UInt32]
        $CommunicationAttempts,

        [Parameter()]
        [System.UInt32]
        $CommunicationTimeout,

        [Parameter()]
        [System.UInt32]
        $LoginFormTimeout
    )

    begin {
        AssertXDModule -Name 'UtilsModule','StoresModule','WebReceiverModule','AuthenticationModule' -Path "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
    }
    process {
        $storefrontCmdletSearchPath = "$env:ProgramFiles\Citrix\Receiver StoreFront\Management"
        Import-Module (FindXDModule -Name 'UtilsModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'StoresModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'WebReceiverModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module (FindXDModule -Name 'AuthenticationModule' -Path $storefrontCmdletSearchPath) -Scope Global -Verbose:$false >$null *>&1
        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false

        try {

            Write-Verbose -Message ($localized.CallingGetSTFStoreService -f $StoreName)
            $StoreService = Get-STFStoreService | Where-object {$_.friendlyname -eq $StoreName};
            Write-Verbose -Message $localized.CallingGetSTFWebReceiverService
            $webreceiverservice = Get-STFWebReceiverService -StoreService $Storeservice
            Write-Verbose -Message $localized.CallingGetDSWebReceiversSummary
            $Configuration = Get-DSWebReceiversSummary | Where-object {$_.StoreVirtualPath -eq ($StoreService.VirtualPath)}
        }
        catch {

            Write-Verbose -Message ($localized.TrappedError -f $Error[0].Exception.Message)
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
                            Write-Verbose -Message ($localized.SettingResourceProperty -f $property)
                            $ChangedParams.Add($property,$PSBoundParameters[$property])
                        }
                    }
                }
                elseif ($expected -ne $actual) {
                    if (!($ChangedParams.ContainsKey($property))) {
                        Write-Verbose -Message ($localized.SettingResourceProperty -f $property)
                        $ChangedParams.Add($property,$PSBoundParameters[$property])
                    }
                }
            }
        }

        #Add in parameters that aren't changed with their current values
        if (!($ChangedParams.ContainsKey('IntervalInMinutes'))) {
            Write-Verbose -Message ($localized.SettingResourceProperty -f 'IntervalInMinutes')
            $ChangedParams.Add('IntervalInMinutes', [System.UInt32]$Configuration.SessionStateTimeout)
        }
        if (!($ChangedParams.ContainsKey('CommunicationAttempts'))) {
            Write-Verbose -Message ($localized.SettingResourceProperty -f 'CommunicationAttempts')
            $ChangedParams.Add('CommunicationAttempts', [System.UInt32]$Configuration.CommunicationAttempts)
        }
        if (!($ChangedParams.ContainsKey('CommunicationTimeout'))) {
            Write-Verbose -Message ($localized.SettingResourceProperty -f 'CommunicationTimeout')
            $ChangedParams.Add('CommunicationTimeout', [System.UInt32]$Configuration.CommunicationTimeout.TotalMinutes)
        }
        if (!($ChangedParams.ContainsKey('LoginFormTimeout'))) {
            Write-Verbose -Message ($localized.SettingResourceProperty -f 'LoginFormTimeout')
            $ChangedParams.Add('LoginFormTimeout', [System.UInt32]$Configuration.LoginFormTimeout)
        }

        $ChangedParams.Remove('StoreName')
        Write-Verbose -Message $localized.CallingSetDSSessionStateTimeout
        Set-DSSessionStateTimeout @ChangedParams
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

        [Parameter()]
        [System.UInt32]
        $IntervalInMinutes,

        [Parameter()]
        [System.UInt32]
        $CommunicationAttempts,

        [Parameter()]
        [System.UInt32]
        $CommunicationTimeout,

        [Parameter()]
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
                    if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual -ErrorAction SilentlyContinue) {
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

