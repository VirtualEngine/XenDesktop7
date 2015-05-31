Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

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
        $itemProperty = Get-ItemProperty -Path $Key -Name $Name -ErrorAction SilentlyContinue;
        if ($itemProperty.$Name) {
            return $itemProperty.$Name;
        }
        return '';
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

function GetXDBrokerMachine {
    <#
        Searches for a registered Citrix XenDesktop machine by name.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [System.String] $MachineName
    )
    if ($MachineName.Contains('.')) {
        ## Attempt to locate the machine by FQDN
        $brokerMachine = Get-BrokerMachine -DNSName $MachineName -ErrorAction SilentlyContinue;
    }
    elseif ($MachineName.Contains('\')) {
        ## Otherwise attempt to locate the machine by DomainName\NetBIOSName
        $brokerMachine = Get-BrokerMachine -MachineName $MachineName -ErrorAction SilentlyContinue;
    }
    else {
        ## Failing all else, perform a wildcard search
        $brokerMachine = Get-BrokerMachine -MachineName "*\$MachineName" -ErrorAction SilentlyContinue;
    }
    if ($brokerMachine -eq $null) {
        Write-Error -ErrorId 'MachineNotFound' -Message ($localizedData.MachineNotFoundError -f $Machine);
        return;
    }
    elseif (($brokerMachine).Count -gt 1) {
        Write-Error -ErrorId 'AmbiguousMachineReference' -Message ($localizedData.AmbiguousMachineReferenceError -f $MachineName);
        return;
    }
    else {
        return $brokerMachine;
    }
}

function TestXDMachineIsExistingMember {
    <#
        Tests whether a machine is an existing member of a list of FQDN machine members.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [System.String] $MachineName,
        [Parameter()] [System.String[]] $ExistingMembers
    )
    if ((-not $MachineName.Contains('\')) -and (-not $MachineName.Contains('.'))) {
        Write-Warning -Message ($localizedData.MachineNameNotFullyQualifiedWarning -f $MachineName);
        $netBIOSName = $MachineName;
    }
    elseif ($MachineName.Contains('\')) {
        $netBIOSName = $MachineName.Split('\')[1];
    }
            
    if ($ExistingMembers -contains $MachineName) {
        return $true;
    }
    elseif ($ExistingMembers -like '{0}.*' -f $netBIOSName) {
        return $true;
    }
    else {
        return $false;
    }
} #end function TestXDMachine

function TestXDMachineMembership {
    <#
        Provides a centralised function to test whether machine membership of a Machine Catalog or
        Delivery Group are correct - evaluating FQDNs, DOMAINNAME\NETBIOS and NETBIOS name formats.
    #>
    param (
        [Parameter(Mandatory)] [System.String[]] $RequiredMembers,
        [Parameter(Mandatory)] [ValidateSet('Present','Absent')] [System.String] $Ensure,
        [Parameter()] [System.String[]] $ExistingMembers
    )
    process {
        $isInCompliance = $true;
        foreach ($member in $RequiredMembers) {
            if (TestXDMachineIsExistingMember -MachineName $member -ExistingMembers $ExistingMembers) {
                if ($Ensure -eq 'Absent') {
                    Write-Verbose ($localizedData.SurplusMachineReference -f $member);
                    $isInCompliance = $false;
                }
            }
            else {
                if ($Ensure -eq 'Present') {
                    Write-Verbose ($localizedData.MissingMachineReference -f $member);
                    $isInCompliance = $false;
                }
            }
        } #end foreach member
        return $isInCompliance;
    } #end process
} #end function TestXDMachineMembers

function ResolveXDBrokerMachine {
    <#
        Returns a machine machine from an existing collection of Citrix XenDesktop
        machines assigned to a Machine Catalog or Delivery Group
    #>
    param (
        [Parameter(Mandatory)] [System.String] $MachineName,
        [Parameter(Mandatory)] [AllowNull()] [System.Object[]] $BrokerMachines
    )
    $brokerMachine = $null;
    foreach ($machine in $brokerMachines) {
        ## Try matching on DNS name
        if (($machine.DNSName -eq $MachineName) -or ($machine.MachineName -eq $MachineName)) {
            return $machine;
        }
        elseif ((-not $MachineName.Contains('\')) -and ($machine.MachineName -match '^\S+\\{0}$' -f $MachineName)) {
            ## Try matching based on DOMAIN\NETBIOS name
            return $machine
        }
    } #end foreach machine
    return $null;
} #end function ResolveXDBrokerMachine

function ThrowInvalidOperationException {
    <#
    .SYNOPSIS
        Throws terminating error of category NotInstalled with specified errorId and errorMessage.
    #>
    param(
        [Parameter(Mandatory)] [System.String] $ErrorId,
        [Parameter(Mandatory)] [System.String] $ErrorMessage
    )
    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument;
    $exception = New-Object -TypeName 'System.InvalidOperationException' -ArgumentList $ErrorMessage;
    $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $exception, $ErrorId, $errorCategory, $null;
    throw $errorRecord;

}

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

function ThrowOperationCanceledException {
    <#
    .SYNOPSIS
        Throws terminating error of category InvalidOperation with specified errorId and errorMessage.
    #>
    param(
        [Parameter(Mandatory)] [System.String] $ErrorId,
        [Parameter(Mandatory)] [System.String] $ErrorMessage
    )
    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
    $exception = New-Object -TypeName 'System.OperationCanceledException' -ArgumentList $ErrorMessage;
    $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $exception, $ErrorId, $errorCategory, $null;
    throw $errorRecord;
} #end function ThrowOperationCanceledException

#endregion Private Functions

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