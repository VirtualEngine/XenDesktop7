Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [System.String] $DeliveryGroup, # Delivery Group Name
        [Parameter(Mandatory)] [ValidateSet('AccessGateway','Direct')] [System.String] $AccessType, # NotViaAG | ViaAG
        [Parameter()] [System.Boolean] $Enabled = $true,
        [Parameter()] [System.Boolean] $AllowRestart = $true,
        [Parameter()] [ValidateSet('HDX','RDP')] [System.String[]] $Protocol = @('HDX','RDP'),
        [Parameter()] [System.String] $Name, # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()] [AllowNull()] [System.String] $Description = $null,
        [Parameter()] [ValidateNotNull()] [System.String[]] $IncludeUsers = @(), # IncludedUsersFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()] [System.String[]] $ExcludeUsers = @(), # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.Broker.Admin.V2' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
        if ([System.String]::IsNullOrEmpty($Name)) {
            $Name = '{0}_Direct' -f $DeliveryGroup;
            if ($AccessType -eq 'AccessGateway') { $Name = '{0}_AG' -f $DeliveryGroup; }
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $desktopGroup = Get-BrokerDesktopGroup -Name $using:DeliveryGroup -ErrorAction Stop;
            $desktopGroupAccessPolicy = Get-BrokerAccessPolicyRule -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;
            $targetResource = @{
                DeliveryGroup = $using:DeliveryGroup;
                AccessType = 'Direct';
                Enabled = $desktopGroupAccessPolicy.Enabled;
                AllowRestart = $desktopGroupAccessPolicy.AllowRestart;
                Protocol = [System.String[]] $desktopGroupAccessPolicy.AllowedProtocols;
                Description = [System.String] $desktopGroupAccessPolicy.Description;
                IncludeUsers = @()
                ExcludeUsers = @();
                Ensure = 'Absent';
                Name = $using:Name;
                Credential = $using:Credential;
            }
            $targetResource['IncludeUsers'] += $desktopGroupAccessPolicy.IncludedUsers | Where Name -ne $null | Select -ExpandProperty Name;
            $targetResource['ExcludeUsers'] += $desktopGroupAccessPolicy.ExcludedUsers | Where Name -ne $null | Select -ExpandProperty Name;
            if ($desktopGroupAccessPolicy) {
                $targetResource.Ensure = 'Present';
            }
            if ($desktopGroupAccessPolicy.AllowedConnections -eq 'ViaAG') {
                $targetResource.AccessType = 'AccessGateway';
            };
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
        [Parameter(Mandatory)] [ValidateSet('AccessGateway','Direct')] [System.String] $AccessType, # NotViaAG | ViaAG
        [Parameter()] [System.Boolean] $Enabled = $true,
        [Parameter()] [System.Boolean] $AllowRestart = $true,
        [Parameter()] [ValidateSet('HDX','RDP')] [System.String[]] $Protocol = @('HDX','RDP'),
        [Parameter()] [System.String] $Name, # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()] [AllowNull()] [System.String] $Description = $null,
        [Parameter()] [ValidateNotNull()] [System.String[]] $IncludeUsers = @(), # IncludedUsersFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()] [System.String[]] $ExcludeUsers = @(), # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if ([System.String]::IsNullOrEmpty($Name)) {
            $Name = '{0}_Direct' -f $DeliveryGroup;
            if ($AccessType -eq 'AccessGateway') { $Name = '{0}_AG' -f $DeliveryGroup; }
        }
    } #end begin
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        $isInCompliance = $true;
        if ($targetResource['Ensure'] -ne $Ensure) { $isInCompliance = $false; }
        elseif ($targetResource['AccessType'] -ne $AccessType) { $isInCompliance = $false; }
        elseif ($targetResource['Enabled'] -ne $Enabled) { $isInCompliance = $false; }
        elseif ($targetResource['AllowRestart'] -ne $AllowRestart) { $isInCompliance = $false; }
        elseif ($targetResource['Name'] -ne $Name) { $isInCompliance = $false; }
        elseif ($targetResource['Description'] -ne $Description) { $isInCompliance = $false; }
        elseif (Compare-Object -ReferenceObject $Protocol -DifferenceObject $targetResource['Protocol']) { $isInCompliance = $false; }
        elseif (Compare-Object -ReferenceObject $ExcludeUsers -DifferenceObject $targetResource['ExcludeUsers']) { $isInCompliance = $false; }
        elseif (Compare-Object -ReferenceObject $IncludeUsers -DifferenceObject $targetResource['IncludeUsers']) { $isInCompliance = $false; }
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
        [Parameter(Mandatory)] [ValidateSet('AccessGateway','Direct')] [System.String] $AccessType, # NotViaAG | ViaAG
        [Parameter()] [System.Boolean] $Enabled = $true,
        [Parameter()] [System.Boolean] $AllowRestart = $true,
        [Parameter()] [ValidateSet('HDX','RDP')] [System.String[]] $Protocol = @('HDX','RDP'),
        [Parameter()] [System.String] $Name, # Name example: <DeliveryGroupName>_Direct or <DeliveryGroupName>_AG
        [Parameter()] [AllowNull()] [System.String] $Description = $null,
        [Parameter()] [ValidateNotNull()] [System.String[]] $IncludeUsers = @(), # IncludedUsersFilterEnabled/IncludedUsers
        [Parameter()] [ValidateNotNull()] [System.String[]] $ExcludeUsers = @(), # ExcludedUserFilterEnabled/ExcludedUsers
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.Broker.Admin.V2' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
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
                if ($using:AccessType -eq 'AccessGateway') { $allowedConnections = 'ViaAG'; }
                else { $allowedConnections = 'NotViaAG'; }
                $accessPolicyParams = @{
                    Enabled = $using:Enabled;
                    Description = $using:Description;
                    AllowRestart = $using:AllowRestart;
                    AllowedConnections = $allowedConnections;
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
                        if (-not $brokerUser) { $brokerUser = New-BrokerUser -Name $user -ErrorAction Stop; }
                        $accessPolicyParams['IncludedUsers'] += $brokerUser;
                    }
                }

                if ($using:ExcludeUsers.Count -ge 1) {
                    $accessPolicyParams['ExcludedUserFilterEnabled'] = $true;
                    foreach ($user in $using:ExcludeUsers) {
                        $brokerUser = Get-BrokerUser -FullName $user -ErrorAction SilentlyContinue;
                        if (-not $brokerUser) { $brokerUser = New-BrokerUser -Name $user -ErrorAction Stop; }
                        $accessPolicyParams['ExcludedUsers'] += $brokerUser;
                    }
                }
                                
                if ($desktopGroupAccessPolicy) {
                    ## Can't change name or delivery group
                    if ($desktopGroup.Uid -ne $desktopGroupAccessPolicy.DesktopGroupUid) { throw; }
                    elseif ($using:Name -ne $desktopGroupAccessPolicy.Name) { throw; }
                    Write-Verbose ($using:localizedData.UpdatingAccessPolicy -f $using:Name);
                    $desktopGroupAccessPolicy | Set-BrokerAccessPolicyRule @accessPolicyParams;
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
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Enabled, $Ensure)));
        return Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
