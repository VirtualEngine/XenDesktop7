Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7EntitlementPolicy.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        # Delivery Group Name
        [Parameter(Mandatory)]
        [System.String] $DeliveryGroup,

        # BrokerEntitlementPolicyRule | BrokerAppEntitlementPolicyRule
        [Parameter(Mandatory)] [ValidateSet('Desktop','Application')]
        [System.String] $EntitlementType,

        [Parameter()]
        [System.Boolean] $Enabled = $true,

        [Parameter()] [AllowNull()]
        [System.String] $Name = $null,

        [Parameter()] [AllowNull()]
        [System.String] $Description = $null,

        # IncludedUserFilterEnabled/IncludedUsers
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
            $Name = '{0}_{1}' -f $DeliveryGroup, $EntitlementType;
        }

    } #end begin
    process {

        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $desktopGroup = Get-BrokerDesktopGroup -Name $using:DeliveryGroup -ErrorAction Stop;
            if ($using:EntitlementType -eq 'Desktop') {
                $entitlementPolicy = Get-BrokerEntitlementPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            }
            elseif ($using:EntitlementType -eq 'Application') {
                $entitlementPolicy = Get-BrokerAppEntitlementPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            }
            $targetResource = @{
                DeliveryGroup = $using:DeliveryGroup;
                EntitlementType = $using:EntitlementType;
                Enabled = $entitlementPolicy.Enabled;
                Description = [System.String] $entitlementPolicy.Description;
                IncludeUsers = @()
                ExcludeUsers = @();
                Ensure = 'Absent';
                Name = $entitlementPolicy.Name;
            }
            $targetResource['IncludeUsers'] += $entitlementPolicy.IncludedUsers | Where-Object Name -ne $null | Select-Object -ExpandProperty Name;
            $targetResource['ExcludeUsers'] += $entitlementPolicy.ExcludedUsers | Where-Object Name -ne $null | Select-Object -ExpandProperty Name;
            if ($entitlementPolicy) {
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
        $scriptBlockParams = @($Name, $Enabled, $Ensure);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        return Invoke-Command  @invokeCommandParams;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        # Delivery Group Name
        [Parameter(Mandatory)]
        [System.String] $DeliveryGroup,

        # BrokerEntitlementPolicyRule | BrokerAppEntitlementPolicyRule
        [Parameter(Mandatory)] [ValidateSet('Desktop','Application')]
        [System.String] $EntitlementType,

        [Parameter()]
        [System.Boolean] $Enabled = $true,

        [Parameter()] [AllowNull()]
        [System.String] $Name = $null,

        [Parameter()] [AllowNull()]
        [System.String] $Description = $null,

        # IncludedUserFilterEnabled/IncludedUsers
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
            $Name = '{0}_{1}' -f $DeliveryGroup, $EntitlementType;
            $PSBoundParameters['Name'] = $Name;
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

        # BrokerEntitlementPolicyRule | BrokerAppEntitlementPolicyRule
        [Parameter(Mandatory)] [ValidateSet('Desktop','Application')]
        [System.String] $EntitlementType,

        [Parameter()]
        [System.Boolean] $Enabled = $true,

        [Parameter()] [AllowNull()]
        [System.String] $Name = $null,

        [Parameter()] [AllowNull()]
        [System.String] $Description = $null,

        # IncludedUserFilterEnabled/IncludedUsers
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
            $Name = '{0}_{1}' -f $DeliveryGroup, $EntitlementType;
        }

    } #end begin
    process {

        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $desktopGroup = Get-BrokerDesktopGroup -Name $using:DeliveryGroup -ErrorAction Stop;
            if ($using:EntitlementType -eq 'Desktop') {
                $entitlementPolicy = Get-BrokerEntitlementPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            }
            elseif ($using:EntitlementType -eq 'Application') {
                $entitlementPolicy = Get-BrokerAppEntitlementPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            }

            if ($using:Ensure -eq 'Present') {
                $entitlementPolicyParams = @{
                    Name = $using:Name;
                    Enabled = $using:Enabled;
                    Description = $using:Description;
                    IncludedUserFilterEnabled = $false;
                    IncludedUsers = @();
                    ExcludedUserFilterEnabled = $false;
                    ExcludedUsers = @();
                }

                if ($IncludeUsers.Count -ge 1) {
                    $entitlementPolicyParams['IncludedUserFilterEnabled'] = $true;
                    foreach ($user in $using:IncludeUsers) {
                        $brokerUser = Get-BrokerUser -FullName $user -ErrorAction SilentlyContinue;
                        if (-not $brokerUser) {
                            $brokerUser = New-BrokerUser -Name $user -ErrorAction Stop;
                        }
                        $entitlementPolicyParams['IncludedUsers'] += $brokerUser;
                    }
                }

                if ($ExcludeUsers.Count -ge 1) {
                    $entitlementPolicyParams['ExcludedUserFilterEnabled'] = $true;
                    foreach ($user in $using:ExcludeUsers) {
                        $brokerUser = Get-BrokerUser -FullName $user -ErrorAction SilentlyContinue;
                        if (-not $brokerUser) {
                            $brokerUser = New-BrokerUser -Name $user -ErrorAction Stop;
                        }
                        $entitlementPolicyParams['ExcludedUsers'] += $brokerUser;
                    }
                }

                if ($entitlementPolicy) {
                    if ($using:EntitlementType -eq 'Desktop') {
                        $entitlementPolicyParams['PublishedName'] = $using:Name;
                        Write-Verbose ($using:localizedData.UpdatingDesktopEntitlementPolicy -f $using:Name);
                        $entitlementPolicy | Set-BrokerEntitlementPolicyRule @entitlementPolicyParams;
                    }
                    else {
                        Write-Verbose ($using:localizedData.UpdatingAppEntitlementPolicy -f $using:Name);
                        $entitlementPolicy | Set-BrokerAppEntitlementPolicyRule @entitlementPolicyParams;
                    }
                }
                else {
                    $entitlementPolicyParams['DesktopGroupUid'] = $desktopGroup.Uid;
                    if ($using:EntitlementType -eq 'Desktop') {
                        $entitlementPolicyParams['PublishedName'] = $using:Name;
                        Write-Verbose ($using:localizedData.AddingDesktopEntitlementPolicy -f $using:Name);
                        New-BrokerEntitlementPolicyRule @entitlementPolicyParams;
                    }
                    else {
                        Write-Verbose ($using:localizedData.AddingAppEntitlementPolicy -f $using:Name);
                        New-BrokerAppEntitlementPolicyRule @entitlementPolicyParams;
                    }
                }
            }
            else {
                if ($entitlementPolicy -and ($using:EntitlementType -eq 'Desktop')) {
                    Write-Verbose ($using:localizedData.RemovingEntitlementPolicy -f $using:Name);
                    $entitlementPolicy | Remove-BrokerEntitlementPolicyRule;
                }
                elseif ($entitlementPolicy) {
                    Write-Verbose ($using:localizedData.RemovingEntitlementPolicy -f $using:Name);
                    $entitlementPolicy | Remove-BrokerAppEntitlementPolicyRule;
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
        $scriptBlockParams = @($Name, $Enabled, $Ensure);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        [ref] $null = Invoke-Command  @invokeCommandParams;

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
