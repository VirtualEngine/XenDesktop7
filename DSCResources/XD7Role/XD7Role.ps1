Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $RoleScope = 'All'
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
            try {
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
            }
            catch {
                Write-Error $_;
            }
        } #end scriptblock
        $invokeCommandParams = @{
            ComputerName = $env:COMPUTERNAME;
            Credential = $Credential;
            Authentication = 'Credssp';
            ScriptBlock = $scriptBlock;
            ArgumentList = @($Name, $RoleScope, $Members, $Ensure);
            ErrorAction = 'Stop';
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
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $RoleScope = 'All'
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
            }
        }
        else {
            foreach ($member in $Members) {
                ## Ensure that the controller is NOT in the list
                if ($targetResource.Members -contains $member) {
                    Write-Verbose ($localizedData.SurplusRoleMember -f $member);
                    $targetResource.Ensure = 'Present';
                }
            }
        }
        return $targetResource.Ensure -eq $Ensure;
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $RoleScope = 'All'
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
            $VerbosePreference = 'Continue';
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            try {
                if ($Ensure -eq 'Present') {
                    foreach ($member in $Members) {
                        Write-Verbose ('Adding Citrix XenDesktop 7.x Administrator "{0}" to role "{1}".' -f $member, $Name);
                        Add-AdminRight -Administrator $member -Role $Name -Scope $RoleScope;
                    }
                }
                else {
                    foreach ($member in $Members) {
                        $hasAdminRights = Get-AdminAdministrator -Name $member | Select-Object -ExpandProperty Rights | Where-Object { $_.RoleName -eq $Name -and $_.ScopeName -eq $RoleScope };
                        if ($hasAdminRights) {
                            Write-Verbose ('Removing Citrix XenDesktop 7.x Administrator "{0}" from role "{1}".' -f $member, $Name);
                            Remove-AdminRight -Administrator $member -Role $Name -Scope $RoleScope;
                        }
                    }
                }
            }
            catch {
                Write-Error $_;
            }
        } #end scriptblock
        $invokeCommandParams = @{
            ComputerName = $env:COMPUTERNAME;
            Credential = $Credential;
            Authentication = 'Credssp';
            ScriptBlock = $scriptBlock;
            ArgumentList = @($Name, $RoleScope, $Members, $Ensure);
            ErrorAction = 'Stop';
        }
        Invoke-Command @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
