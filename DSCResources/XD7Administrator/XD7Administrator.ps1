Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.Boolean] $Enabled = $true
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.DelegatedAdmin.Admin.V1' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.DelegatedAdmin.Admin.V1 module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            try {
                $xdAdministrator = Get-AdminAdministrator -Name $using:Name -ErrorAction SilentlyContinue;
            }
            catch {}

            $targetResource = @{
                Name = $using:Name;
                Enabled = [System.Boolean] $xdAdministrator.Enabled;
                Ensure = 'Absent';
            };
            if ($xdAdministrator) {
                $targetResource['Ensure'] = 'Present';
            }
            return $targetResource;
        } #end scriptblock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Enabled, $Ensure)));
        $targetResource = Invoke-Command  @invokeCommandParams;
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.Boolean] $Enabled = $true
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        $isInCompliance = $true;
        if ($Ensure -ne $targetResource['Ensure']) {
            $isInCompliance = $false;
        }
        elseif (($Ensure -eq 'Present')-and ($Enabled -ne $targetResource['Enabled'])) {
            $isInCompliance = $false;
        }

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
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.Boolean] $Enabled = $true
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.DelegatedAdmin.Admin.V1' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.DelegatedAdmin.Admin.V1 module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            try {
                ## Cmdlet ignores $ErrorActionPreference :@
                $xdAdministrator = Get-AdminAdministrator -Name $using:Name -ErrorAction SilentlyContinue;
            }
            catch {}

            if ($using:Ensure -eq 'Present') {
                if ($xdAdministrator) {
                    Write-Verbose ('Updating Citrix XenDesktop 7.x Administrator "{0}".' -f $using:Name);
                    Set-AdminAdministrator -Name $using:Name -Enabled $using:Enabled;
                }
                else {
                    Write-Verbose ('Creating Citrix XenDesktop 7.x Administrator "{0}".' -f $using:Name);
                    New-AdminAdministrator -Name $using:Name -Enabled $using:Enabled;                        
                }
            }
            else {
                if ($xdAdministrator) {
                    Write-Verbose ('Removing Citrix XenDesktop 7.x Administrator "{0}".' -f $using:Name);
                    Remove-AdminAdministrator -Name $using:Name;
                }
            }
        } #end scriptblock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Enabled, $Ensure)));
        Invoke-Command  @invokeCommandParams;    } #end process
} #end function Set-TargetResource
