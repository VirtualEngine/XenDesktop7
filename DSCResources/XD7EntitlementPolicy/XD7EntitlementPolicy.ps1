Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [System.String] $DeliveryGroup, # Delivery Group Name
        [Parameter(Mandatory)] [ValidateSet('Desktop','Application')] [System.String] $EntitlementType, # BrokerEntitlementPolicyRule | BrokerAppEntitlementPolicyRule
        [Parameter()] [System.Boolean] $Enabled = $true,
        [Parameter()] [System.String] $Name, # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()] [AllowNull()] [System.String] $Description = $null,
        [Parameter()] [ValidateNotNull()] [System.String[]] $IncludeUsers = @(), # IncludedUserFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()] [System.String[]] $ExcludeUsers = @(), # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.Broker.Admin.V2' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
        if ([System.String]::IsNullOrEmpty($Name)) {
            $Name = '{0}_{1}' -f $DeliveryGroup, $EntitlementType;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $desktopGroup = Get-BrokerDesktopGroup -Name $using:DeliveryGroup -ErrorAction Stop;
            if ($using:EntitlementType -eq 'Desktop') {
                $entitlementPolicy = Get-BrokerEntitlementPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            }
            elseif ($using:EntitlementType -eq 'Application') {
                $entitlementPolicy = Get-AppBrokerEntitlementPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            }
            $targetResource = @{
                DeliveryGroup = $using:DeliveryGroup;
                EntitlementType = $using:EntitlementType;
                Enabled = $entitlementPolicy.Enabled;
                Description = [System.String] $entitlementPolicy.Description;
                IncludeUsers = @()
                ExcludeUsers = @();
                Ensure = 'Absent';
                Name = $using:Name;
                Credential = $using:Credential;
            }
            $targetResource['IncludeUsers'] += $entitlementPolicy.IncludedUsers | Where Name -ne $null | Select -ExpandProperty Name;
            $targetResource['ExcludeUsers'] += $entitlementPolicy.ExcludedUsers | Where Name -ne $null | Select -ExpandProperty Name;
            if ($entitlementPolicy) {
                $targetResource.Ensure = 'Present';
            }
            return $targetResource;
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Enabled, $Ensure)));
        return Invoke-Command  @invokeCommandParams;
    }
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [System.String] $DeliveryGroup, # Delivery Group Name
        [Parameter(Mandatory)] [ValidateSet('Desktop','Application')] [System.String] $EntitlementType, # BrokerEntitlementPolicyRule | BrokerAppEntitlementPolicyRule
        [Parameter()] [System.Boolean] $Enabled = $true,
        [Parameter()] [System.String] $Name, # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()] [AllowNull()] [System.String] $Description = $null,
        [Parameter()] [ValidateNotNull()] [System.String[]] $IncludeUsers = @(), # IncludedUserFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()] [System.String[]] $ExcludeUsers = @(), # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if ([System.String]::IsNullOrEmpty($Name)) {
            $Name = '{0}_{1}' -f $DeliveryGroup, $EntitlementType;
        }
    } #end begin
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        $isInCompliance = $true;
        if ($targetResource['Ensure'] -ne $Ensure) { Write-Host "1"; $isInCompliance = $false; }
        elseif ($targetResource['Enabled'] -ne $Enabled) { Write-Host "2";$isInCompliance = $false; }
        elseif ($targetResource['Name'] -ne $Name) { Write-Host "3";$isInCompliance = $false; }
        elseif ($targetResource['Description'] -ne $Description) {  Write-Host "5a"; $isInCompliance = $false; }
        elseif (Compare-Object -ReferenceObject $ExcludeUsers -DifferenceObject $targetResource['ExcludeUsers']) { Write-Host "4"; $isInCompliance = $false; }
        elseif (Compare-Object -ReferenceObject $IncludeUsers -DifferenceObject $targetResource['IncludeUsers']) { Write-Host "5"; $isInCompliance = $false; }
        if ($isInCompliance) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $Name);
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $Name);
        }
        return $isInCompliance;
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [System.String] $DeliveryGroup, # Delivery Group Name
        [Parameter(Mandatory)] [ValidateSet('Desktop','Application')] [System.String] $EntitlementType, # BrokerEntitlementPolicyRule | BrokerAppEntitlementPolicyRule
        [Parameter()] [System.Boolean] $Enabled = $true,
        [Parameter()] [System.String] $Name, # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()] [AllowNull()] [System.String] $Description = $null,
        [Parameter()] [ValidateNotNull()] [System.String[]] $IncludeUsers = @(), # IncludedUserFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()] [System.String[]] $ExcludeUsers = @(), # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.Broker.Admin.V2' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
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
                $entitlementPolicy = Get-AppBrokerEntitlementPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            }
            
            if ($using:Ensure -eq 'Present') {
                $entitlementPolicyParams = @{
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
                        if (-not $brokerUser) { $brokerUser = New-BrokerUser -Name $user -ErrorAction Stop; }
                        $entitlementPolicyParams['IncludedUsers'] += $brokerUser;
                    }
                }

                if ($ExcludeUsers.Count -ge 1) {
                    $entitlementPolicyParams['ExcludedUserFilterEnabled'] = $true;
                    foreach ($user in $using:ExcludeUsers) {
                        $brokerUser = Get-BrokerUser -FullName $user -ErrorAction SilentlyContinue;
                        if (-not $brokerUser) { $brokerUser = New-BrokerUser -Name $user -ErrorAction Stop; }
                        $entitlementPolicyParams['ExcludedUsers'] += $brokerUser;
                    }
                }
                                
                if ($entitlementPolicy) {
                    if ($using:EntitlementType -eq 'Desktop') {
                        Write-Verbose ($using:localizedData.UpdatingDesktopEntitlementPolicy -f $using:Name);
                        $entitlementPolicy | Set-BrokerEntitlementPolicyRule @entitlementPolicyParams;
                    }
                    else {
                        Write-Verbose ($using:localizedData.UpdatingAppEntitlementPolicy -f $using:Name);
                        $entitlementPolicy | Set-BrokerAppEntitlementPolicyRule @entitlementPolicyParams;
                    }
                }
                else {
                    $entitlementPolicyParams['Name'] = $using:Name;
                    $entitlementPolicyParams['DesktopGroupUid'] = $desktopGroup.Uid;
                    if ($using:EntitlementType -eq 'Desktop') {
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
                if ($desktopGroupAccessPolicy) {
                    Write-Verbose ($using:localizedData.RemovingEntitlementPolicy -f $using:Name);
                    $desktopGroupAccessPolicy | Remove-BrokerAccessPolicyRule;
                }
            }

        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Enabled, $Ensure)));
        return Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
