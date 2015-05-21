Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $RoleScope = 'All',
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.DelegatedAdmin.Admin.V1' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.DelegatedAdmin.Admin.V1 module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            param (
                [System.String] $Name,
                [System.String] $RoleScope,
                [System.String[]] $Members,
                [System.String] $Ensure
            )
            $VerbosePreference = 'Continue';
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            $xdAdminRoleMembers = Get-AdminAdministrator |
                Select-Object -Property Name -ExpandProperty Rights |
                    Where-Object { $_.RoleName -eq $Name -and $_.ScopeName -eq $RoleScope } |
                        Select-Object -ExpandProperty Name;
            $targetResource = @{
                Name = $Name;
                Scope = $RoleScope;
                Members = ,$xdAdminRoleMembers;
                Ensure = $Ensure;
            };
            return [PSCustomObject] $targetResource;
        } #end scriptblock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($Name, $RoleScope, $Members, $Ensure);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        $targetResource = Invoke-Command @invokeCommandParams;
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
        if ($Ensure -eq 'Present') {
            foreach ($member in $Members) {
                ## Ensure that the controller is in the list
                if ($targetResource.Members -notcontains $member) {
                    Write-Verbose ($localizedData.MissingRoleMember -f $member);

                    $targetResource.Ensure = 'Absent';
                }
            } #end foreach member
        }
        else {
            foreach ($member in $Members) {
                ## Ensure that the controller is NOT in the list
                if ($targetResource.Members -contains $member) {
                    Write-Verbose ($localizedData.SurplusRoleMember -f $member);
                    $targetResource.Ensure = 'Present';
                }
            } #end foreach member
        }
        if ($targetResource.Ensure -eq $Ensure) {
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
        [Parameter()] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.DelegatedAdmin.Admin.V1' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.DelegatedAdmin.Admin.V1 module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            param (
                [System.String] $Name,
                [System.String] $RoleScope,
                [System.String] $Members,
                [System.String] $Ensure
            )
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            data localizedData {
                ConvertFrom-StringData @'
                    AddingRoleMember = Adding Citrix XenDesktop 7.x Administrator '{0}' to role '{1}'.
                    RemovingRoleMember = Adding Citrix XenDesktop 7.x Administrator '{0}' to role '{1}'.
'@
            }
            if ($Ensure -eq 'Present') {
                foreach ($member in $Members) {
                    Write-Verbose ($localizedData.AddingRoleMember -f $member, $Name);
                    Add-AdminRight -Administrator $member -Role $Name -Scope $RoleScope;
                }
            }
            else {
                foreach ($member in $Members) {
                    $hasAdminRights = Get-AdminAdministrator -Name $member | Select-Object -ExpandProperty Rights | Where-Object { $_.RoleName -eq $Name -and $_.ScopeName -eq $RoleScope };
                    if ($hasAdminRights) {
                        Write-Verbose ($localizedData.RemovingRoleMember -f $member, $Name);
                        Remove-AdminRight -Administrator $member -Role $Name -Scope $RoleScope;
                    }
                }
            }
        } #end scriptblock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($Name, $RoleScope, $Members, $Ensure);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        Invoke-Command @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
