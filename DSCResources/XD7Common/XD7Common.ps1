#region Private Functions

function AddInvokeScriptBlockCredentials {
    <#
    .SYNOPSIS
        Adds the required Invoke-Command parameters for loopback processing with CredSSP.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [System.Collections.Hashtable] $Hashtable,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $Hashtable['ComputerName'] = $env:COMPUTERNAME;
        $Hashtable['Credential'] = $Credential;
        $Hashtable['Authentication'] = 'Credssp';
    }
} #end function AddInvokeScriptBlockCredentials

function GetHostname {
    [CmdletBinding()]
    [OutputType([System.String])]
    param ( )
    process {
        $globalIpProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties();
        if ($globalIpProperties.DomainName) {
            return '{0}.{1}' -f $globalIpProperties.HostName, $globalIpProperties.DomainName;
        }
        else {
            return $globalIpProperties.HostName;
        }
    } #end process
} #end function GetHostname

function GetRegistryValue {
    <#
    .SYNOPSIS
        Returns a registry string value.
    .NOTES
        This is an internal function and shouldn't be called from outside.
        This function enables registry calls to be unit tested.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Registry key name/path to query.
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [Alias('Path')] [System.String] $Key,
        # Registry value to return.
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name
    )
    process {
        return Get-ItemProperty -Path $Key | Select-Object -ExpandProperty $Name;
    }
} #end function GetRegistryValue

function StartWaitProcess {
    <#
    .SYNOPSIS
        Starts and waits for a process to exit.
    .NOTES
        This is an internal function and shouldn't be called from outside.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Int32])]
    param (
        # Path to process to start.
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $FilePath,
        # Arguments (if any) to apply to the process.
        [Parameter()] [AllowNull()] [System.String[]] $ArgumentList,
        # Credential to start the process as.
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        # Working directory
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $WorkingDirectory = (Split-Path -Path $FilePath -Parent)
    )
    process {
        $startProcessParams = @{
            FilePath = $FilePath;
            WorkingDirectory = $WorkingDirectory;
            NoNewWindow = $true;
            PassThru = $true;
        };
        $displayParams = '<None>';
        if ($ArgumentList) {
            $displayParams = [System.String]::Join(' ', $ArgumentList);
            $startProcessParams['ArgumentList'] = $ArgumentList;
        }
        Write-Verbose ($localizedData.StartingProcess -f $FilePath, $displayParams);
        if ($Credential) {
            Write-Verbose ($localizedData.StartingProcessAs -f $Credential.UserName);
            $startProcessParams['Credential'] = $Credential;
        }
        if ($PSCmdlet.ShouldProcess($FilePath, 'Start Process')) {
            $process = Start-Process @startProcessParams -ErrorAction Stop;
        }
        if ($PSCmdlet.ShouldProcess($FilePath, 'Wait Process')) {
            Write-Verbose ($localizedData.ProcessLaunched -f $process.Id);
            Write-Verbose ($localizedData.WaitingForProcessToExit -f $process.Id);
            $process.WaitForExit();
            $exitCode = [System.Convert]::ToInt32($process.ExitCode);
            Write-Verbose ($localizedData.ProcessExited -f $process.Id, $exitCode);
        }
        return $exitCode;
    } #end process
} #end function StartWaitProcess

function FindXDModule {
    <#
    .SYNOPSIS
        Locates a module's manifest (.psd1) file.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Name = 'Citrix.XenDesktop.Admin',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Path = 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1'
    )
    process {
        $module = Get-ChildItem -Path $Path -Include "$Name.psd1" -File -Recurse;
        return $module.FullName;
    } #end process
} #end function FindModule

function TestXDModule {
    <#
    .SYNOPSIS
        Tests whether Powershell modules or Snapin are available/registered.
    #>
    [CmdletBinding()]
    param (
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Name = 'Citrix.XenDesktop.Admin',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Path = 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1',
        [Parameter()] [System.Management.Automation.SwitchParameter] $IsSnapin
    )
    process {
        if ($IsSnapin) {
            if (Get-PSSnapin -Name $Name -Registered) {
                return $true;
            }
        }
        else {
            if (FindXDModule @PSBoundParameters) {
                return $true;
            }
        }
        return $false;
    } #end process
} #end TestModule

function ThrowInvalidProgramException {
    <#
    .SYNOPSIS
        Throws terminating error of category NotInstalled with specified errorId and errorMessage.
    #>
    param(
        [Parameter(Mandatory)] [System.String] $ErrorId,
        [Parameter(Mandatory)] [System.String] $ErrorMessage
    )
    $errorCategory = [System.Management.Automation.ErrorCategory]::NotInstalled;
    $exception = New-Object -TypeName 'System.InvalidProgramException' -ArgumentList $ErrorMessage;
    $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $exception, $ErrorId, $errorCategory, $null;
    throw $errorRecord;
} #end function ThrowInvalidProgramException

function TestXDInstalledRole {
    <#
    .SYNOPSIS
        Tests whether a Citrix XenDesktop 7.x role is installed.
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        ## Citrix XenDesktop 7.x role to query.
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')] [System.String] $Role
    )
    process {
        if (GetXDInstalledRole -Role $Role) {
            return $true;
        }
        return $false;
    } #end process
} #end function TestXDRole

function GetXDInstalledRole {
    <#
    .SYNOPSIS
        Returns installed Citrix XenDesktop 7.x installed product by role.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        ## Citrix XenDesktop 7.x role to query.
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')] [System.String] $Role
    )
    process {
        $installedProducts = Get-ItemProperty 'HKLM:\SOFTWARE\Classes\Installer\Products\*' |
            Where-Object { $_.ProductName -like '*Citrix*' -and $_.ProductName -notlike '*snap-in' } |
                Select-Object -ExpandProperty ProductName;
        switch ($Role) {
            'Controller' { $filter = 'Citrix Broker Service'; }
            'Studio' { $filter = 'Citrix Studio'; }
            'Storefront' { $filter = 'Citrix Storefront'; }
            'Licensing' { $filter = 'Citrix Licensing'; }
            'Director' { $filter = 'Citrix Director'; }
            'DesktopVDA' { $filter = 'Citrix Virtual Desktop Agent'; }
            'SessionVDA' { $filter = 'Citrix Virtual Desktop Agent'; } # Name: Citrix Virtual Delivery Agent 7.6, DisplayName: Citrix Virtual Desktop Agent?
        }
        return $installedProducts -match $filter;
    } #end process
} #end functoin GetXDInstalledProduct

function ResolveXDSetupMedia {
    <#
    .SYNOPSIS
        Resolve the correct installation media source for the
        local architecture depending on the role.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        ## Citrix XenDesktop 7.x role to install/uninstall.
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')] [System.String] $Role,
        ## Citrix XenDesktop 7.x installation media path.
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SourcePath
    )
    process {
        $architecture = 'x86';
        if ([System.Environment]::Is64BitOperatingSystem) {
            $architecture = 'x64';
        }
        switch ($Role) {
            'DesktopVDA' { $installMedia = 'XenDesktopVdaSetup.exe'; }
            'SessionVDA' { $installMedia = 'XenDesktopVdaSetup.exe'; }
            Default { $installMedia = 'XenDesktopServerSetup.exe'; }
        }
        $sourceArchitecturePath = Join-Path -Path $SourcePath -ChildPath $architecture;
        $installMediaPath = Get-ChildItem -Path $sourceArchitecturePath -Filter $installMedia -Recurse -File;
        if (-not $installMediaPath) {
            throw ($localizedData.NoValidSetupMediaError -f $installMedia, $sourceArchitecturePath);
        }
        return $installMediaPath.FullName;
    } #end process
} #end function ResolveXDSetupMedia

#endregion Private Functions