Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential,
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
            param (
                [System.String] $Name,
                [System.String] $Enabled,
                [System.String] $Ensure
            )
            $VerbosePreference = 'Continue';
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            try {
                $xdAdministrator = Get-AdminAdministrator -Name $Name -ErrorAction SilentlyContinue;
                
                $targetResource = @{
                    Name = $Name;
                    Enabled = [System.Boolean] $xdAdministrator.Enabled;
                    Ensure = 'Absent';
                };
                if ($xdAdministrator) {
                    $targetResource['Ensure'] = 'Present';
                }
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
            ArgumentList = @($Name, $Enabled, $Ensure);
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
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.Boolean] $Enabled = $true
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($Ensure -ne $targetResource.Ensure) { return $false; }
        elseif ($Ensure -eq 'Abesent' -and $Enabled -ne $targetResource.Enabled) { return $false; }
        return $true;

    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential,
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
            param (
                [System.String] $Name,
                [System.Boolean] $Enabled,
                [System.String] $Ensure
            )
            $VerbosePreference = 'Continue';
            Add-PSSnapin -Name 'Citrix.DelegatedAdmin.Admin.V1' -ErrorAction Stop;
            try {
                $xdAdministrator = Get-AdminAdministrator -Name $Name -ErrorAction SilentlyContinue;
                if ($Ensure -eq 'Present') {
                    if ($xdAdministrator) {
                        Write-Verbose ('Updating Citrix XenDesktop 7.x Administrator "{0}".' -f $Name);
                        Set-AdminAdministrator -Name $Name -Enabled $Enabled;
                    }
                    else {
                        Write-Verbose ('Creating Citrix XenDesktop 7.x Administrator "{0}".' -f $Name);
                        New-AdminAdministrator -Name $Name -Enabled $Enabled;                        
                    }
                }
                else {
                    if ($xdAdministrator) {
                        Write-Verbose ('Removing Citrix XenDesktop 7.x Administrator "{0}".' -f $Name);
                        Remove-AdminAdministrator -Name $Name;
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
            ArgumentList = @($Name, $Enabled, $Ensure);
            ErrorAction = 'Stop';
        }
        Invoke-Command @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
