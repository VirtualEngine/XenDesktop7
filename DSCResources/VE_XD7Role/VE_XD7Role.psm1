Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7Role.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $Members,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $RoleScope = 'All',

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {

        AssertXDModule -Name 'Citrix.DelegatedAdmin.Admin.V1' -IsSnapin;

    }
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;

            $xdAdministrators = Get-AdminAdministrator |
                                    ForEach-Object {
                                        [PSCustomObject] @{
                                            Name = $_.Name;
                                            RoleName = $_.Rights.RoleName;
                                            ScopeName = $_.Rights.ScopeName
                                        }
                                    }

            $xdAdminRoleMembers = $xdAdministrators |
                Where-Object { $_.RoleName -eq $using:Name -and $_.ScopeName -eq $using:RoleScope } |
                    ForEach-Object { $_.Name };

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

        $scriptBlockParams = @($Name, $RoleScope, $Members, $Ensure);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
            $targetResource = Invoke-Command  @invokeCommandParams;
        }
        else {
            $invokeScriptBlock = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
            $targetResource = InvokeScriptBlock -ScriptBlock $invokeScriptBlock;
        }
        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $Members,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $RoleScope = 'All',

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $Members,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $RoleScope = 'All',

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {

        AssertXDModule -Name 'Citrix.DelegatedAdmin.Admin.V1' -IsSnapin;

    }
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            if ($using:Ensure -eq 'Present') {

                foreach ($member in $using:Members) {

                    Write-Verbose ($using:localizedData.AddingRoleMember -f $member, $using:Name);
                    Add-AdminRight -Administrator $member -Role $using:Name -Scope $using:RoleScope;
                }

            }
            else {

                foreach ($member in $using:Members) {

                    $hasAdminRights = Get-AdminAdministrator -Name $member | Select-Object -ExpandProperty Rights | Where-Object {
                        $_.RoleName -eq $using:Name -and $_.ScopeName -eq $using:RoleScope
                    };

                    if ($hasAdminRights) {

                        Write-Verbose ($using:localizedData.RemovingRoleMember -f $member, $using:Name);
                        Remove-AdminRight -Administrator $member -Role $using:Name -Scope $using:RoleScope;
                    }
                }
            }

        } #end scriptblock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        $scriptBlockParams = @($Name, $RoleScope, $Members, $Ensure);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
            [ref] $null = Invoke-Command  @invokeCommandParams;
        }
        else {
            $invokeScriptBlock = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
            [ref] $null = InvokeScriptBlock -ScriptBlock $invokeScriptBlock;
        }

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

## Import the InvokeScriptBlock function into the current scope
. (Join-Path -Path (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common') -ChildPath 'InvokeScriptBlock.ps1');

Export-ModuleMember -Function *-TargetResource;
