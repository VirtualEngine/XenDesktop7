Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $RoleScope = 'All',
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.DelegatedAdmin.Admin.V1' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.DelegatedAdmin.Admin.V1' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            $xdAdminRoleMembers = Get-AdminAdministrator |
                Select-Object -Property Name -ExpandProperty Rights |
                    Where-Object { $_.RoleName -eq $using:Name -and $_.ScopeName -eq $using:RoleScope } |
                        ForEach { $_.Name };
            $targetResource = @{
                Name = $using:Name;
                Scope = $using:RoleScope;
                Members = $xdAdminRoleMembers;
                Ensure = $using:Ensure;
            };
            return $targetResource;
        } #end scriptblock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $RoleScope, $Members, $Ensure)));
        $targetResource = Invoke-Command  @invokeCommandParams;
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $RoleScope = 'All',
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        foreach ($member in $Members) {
            $netBIOSName = $member;
            if ($member.Contains('\')) {
                $netBIOSName = $member.Split('\')[1];
            }
            
            ## Try a direct match
            if ($targetResource.Members -contains $member) {
                if ($Ensure -eq 'Absent') {
                    Write-Verbose ($localizedData.SurplusRoleMember -f $member);
                    $targetResource['Ensure'] = 'Present';
                }
            }
            ## If not, try a *\UserName or *\GroupName match
            elseif ($targetResource.Members -match '^\S+\\{0}$' -f $netBIOSName) {
                Write-Warning -Message ($localizedData.UserNameNotFullyQualifiedWarning -f $member);
                if ($Ensure -eq 'Absent') {
                    Write-Verbose ($localizedData.SurplusRoleMember -f $member);
                    $targetResource['Ensure'] = 'Present';
                }
            }
            else {
                if ($Ensure -eq 'Present') {
                    Write-Verbose ($localizedData.MissingRoleMember -f $member);
                    $targetResource['Ensure'] = 'Absent';
                }
            }
        } #end foreach member
        if ($targetResource['Ensure'] -eq $Ensure) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $Name);
            return $true;
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $Name);
            return $false;
        }
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $RoleScope = 'All',
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.DelegatedAdmin.Admin.V1' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.DelegatedAdmin.Admin.V1' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            if ($using:Ensure -eq 'Present') {
                foreach ($member in $using:Members) {
                    $addingRoleMember = 'Adding Citrix XenDesktop 7.x Administrator ''{0}'' to role ''{1}''.';
                    Write-Verbose ($addingRoleMember -f $member, $using:Name);
                    Add-AdminRight -Administrator $member -Role $using:Name -Scope $using:RoleScope;
                }
            }
            else {
                foreach ($member in $using:Members) {
                    $hasAdminRights = Get-AdminAdministrator -Name $member | Select-Object -ExpandProperty Rights | Where-Object { $_.RoleName -eq $using:Name -and $_.ScopeName -eq $using:RoleScope };
                    if ($hasAdminRights) {
                        $removingRoleMember = 'Removing Citrix XenDesktop 7.x Administrator ''{0}'' from role ''{1}''.';
                        Write-Verbose ($removingRoleMember -f $member, $using:Name);
                        Remove-AdminRight -Administrator $member -Role $using:Name -Scope $using:RoleScope;
                    }
                }
            }
        } #end scriptblock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $RoleScope, $Members, $Ensure)));
        $targetResource = Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
