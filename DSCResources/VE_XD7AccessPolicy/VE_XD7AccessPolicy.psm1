Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7AccessPolicy.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
         # Delivery Group Name
        [Parameter(Mandatory)]
        [System.String] $DeliveryGroup,

        # NotViaAG | ViaAG
        [Parameter(Mandatory)] [ValidateSet('AccessGateway','Direct')]
        [System.String] $AccessType,

        [Parameter()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [System.Boolean] $AllowRestart = $true,

        [Parameter()] [ValidateSet('HDX','RDP')]
        [System.String[]] $Protocol = @('HDX','RDP'),

        # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()]
        [System.String] $Name,

        [Parameter()] [AllowNull()]
        [System.String] $Description = $null,

        # IncludedUsersFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()]
        [System.String[]] $IncludeUsers = @(),

        # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateNotNull()]
        [System.String[]] $ExcludeUsers = @(),

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {
        AssertXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin;
        if ([System.String]::IsNullOrEmpty($Name)) {
            $Name = '{0}_Direct' -f $DeliveryGroup;
            if ($AccessType -eq 'AccessGateway') {
                $Name = '{0}_AG' -f $DeliveryGroup;
            }
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $desktopGroup = Get-BrokerDesktopGroup -Name $using:DeliveryGroup -ErrorAction Stop;
            $desktopGroupAccessPolicy = Get-BrokerAccessPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            $targetResource = @{
                DeliveryGroup = $using:DeliveryGroup;
                Name = $desktopGroupAccessPolicy.Name;
                AccessType = if ($desktopGroupAccessPolicy.AllowedConnections -eq 'ViaAG') { 'AccessGateway' } else { 'Direct' }
                Enabled = $desktopGroupAccessPolicy.Enabled;
                AllowRestart = $desktopGroupAccessPolicy.AllowRestart;
                Protocol = [System.String[]] $desktopGroupAccessPolicy.AllowedProtocols;
                Description = [System.String] $desktopGroupAccessPolicy.Description;
                IncludeUsers = @()
                ExcludeUsers = @();
                Ensure = 'Absent';
            }
            $targetResource['IncludeUsers'] += $desktopGroupAccessPolicy.IncludedUsers | Where-Object Name -ne $null | Select-Object -ExpandProperty Name;
            $targetResource['ExcludeUsers'] += $desktopGroupAccessPolicy.ExcludedUsers | Where-Object Name -ne $null | Select-Object -ExpandProperty Name;
            if ($desktopGroupAccessPolicy) {
                $targetResource.Ensure = 'Present';
            }
            return $targetResource;
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        else {
            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Enabled, $Ensure)));
        return Invoke-Command  @invokeCommandParams;
    }
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        # Delivery Group Name
        [Parameter(Mandatory)]
        [System.String] $DeliveryGroup,

        # NotViaAG | ViaAG
        [Parameter(Mandatory)] [ValidateSet('AccessGateway','Direct')]
        [System.String] $AccessType,

        [Parameter()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [System.Boolean] $AllowRestart = $true,

        [Parameter()] [ValidateSet('HDX','RDP')] [System.String[]]
        $Protocol = @('HDX','RDP'),

        # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()]
        [System.String] $Name,

        [Parameter()] [AllowNull()]
        [System.String] $Description = $null,

        # IncludedUsersFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()]
        [System.String[]] $IncludeUsers = @(),

        # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateNotNull()]
        [System.String[]] $ExcludeUsers = @(),

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {
        if ([System.String]::IsNullOrEmpty($Name)) {
            $Name = '{0}_Direct' -f $DeliveryGroup;
            if ($AccessType -eq 'AccessGateway') { $Name = '{0}_AG' -f $DeliveryGroup; }
        }
    } #end begin
    process {
        $PSBoundParameters['Ensure'] = $Ensure;
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
    param (
        # Delivery Group Name
        [Parameter(Mandatory)]
        [System.String] $DeliveryGroup,

        # NotViaAG | ViaAG
        [Parameter(Mandatory)] [ValidateSet('AccessGateway','Direct')]
        [System.String] $AccessType,

        [Parameter()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [System.Boolean] $AllowRestart = $true,

        [Parameter()] [ValidateSet('HDX','RDP')] [System.String[]]
        $Protocol = @('HDX','RDP'),

        # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()]
        [System.String] $Name,

        [Parameter()] [AllowNull()]
        [System.String] $Description = $null,

        # IncludedUsersFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()]
        [System.String[]] $IncludeUsers = @(),

        # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateNotNull()]
        [System.String[]] $ExcludeUsers = @(),

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {
        AssertXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin;
        if ([System.String]::IsNullOrEmpty($Name)) {
            $Name = '{0}_Direct' -f $DeliveryGroup;
            if ($AccessType -eq 'AccessGateway') { $Name = '{0}_AG' -f $DeliveryGroup; }
        }
    } #end begin
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $desktopGroup = Get-BrokerDesktopGroup -Name $using:DeliveryGroup -ErrorAction Stop;
            $desktopGroupAccessPolicy = Get-BrokerAccessPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;

            if ($using:Ensure -eq 'Present') {
                $accessPolicyParams = @{
                    Enabled = $using:Enabled;
                    Description = $using:Description;
                    AllowRestart = $using:AllowRestart;
                    AllowedConnections = if ($using:AccessType -eq 'AccessGateway') { 'ViaAG' } else { 'NotViaAG' }
                    AllowedProtocols = $using:Protocol;
                    IncludedUserFilterEnabled = $false;
                    IncludedUsers = @();
                    ExcludedUserFilterEnabled = $false;
                    ExcludedUsers = @();
                }

                if ($using:IncludeUsers.Count -ge 1) {
                    $accessPolicyParams['IncludedUserFilterEnabled'] = $true;
                    foreach ($user in $using:IncludeUsers) {
                        $brokerUser = Get-BrokerUser -FullName $user -ErrorAction SilentlyContinue;
                        if (-not $brokerUser) {
                            $brokerUser = New-BrokerUser -Name $user -ErrorAction Stop;
                        }
                        $accessPolicyParams['IncludedUsers'] += $brokerUser;
                    }
                }

                if ($using:ExcludeUsers.Count -ge 1) {
                    $accessPolicyParams['ExcludedUserFilterEnabled'] = $true;
                    foreach ($user in $using:ExcludeUsers) {
                        $brokerUser = Get-BrokerUser -FullName $user -ErrorAction SilentlyContinue;
                        if (-not $brokerUser) {
                            $brokerUser = New-BrokerUser -Name $user -ErrorAction Stop;
                        }
                        $accessPolicyParams['ExcludedUsers'] += $brokerUser;
                    }
                }

                if ($desktopGroupAccessPolicy) {
                    ## Can't change name or delivery group
                    if ($desktopGroup.Uid -ne $desktopGroupAccessPolicy.DesktopGroupUid) {
                        throw ($using:localizedData.ImmutablePropertyError -f 'Uid');
                    }
                    elseif ($using:Name -ne $desktopGroupAccessPolicy.Name) {
                        throw ($using:localizedData.ImmutablePropertyError -f 'Name');
                    }
                    Write-Verbose ($using:localizedData.UpdatingAccessPolicy -f $using:Name);
                    $null = $desktopGroupAccessPolicy | Set-BrokerAccessPolicyRule @accessPolicyParams;
                }
                else {
                    $accessPolicyParams['Name'] = $using:Name;
                    $accessPolicyParams['DesktopGroupUid'] = $desktopGroup.Uid;
                    Write-Verbose ($using:localizedData.AddingAccessPolicy -f $using:Name);
                    New-BrokerAccessPolicyRule @accessPolicyParams;
                }
            }
            else {
                if ($desktopGroupAccessPolicy) {
                    Write-Verbose ($using:localizedData.RemovingAccessPolicy -f $using:Name);
                    $desktopGroupAccessPolicy | Remove-BrokerAccessPolicyRule;
                }
            }

        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        else {
            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Enabled, $Ensure)));
        [ref] $null = Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
