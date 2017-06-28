Import-LocalizedData -BindingVariable localized -FileName VE_XD7Common.Resources.psd1;

#region Private Functions

function AddInvokeScriptBlockCredentials {
<#
    .SYNOPSIS
        Adds the required Invoke-Command parameters for loopback processing with CredSSP.
#>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [System.Collections.Hashtable] $Hashtable,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [OutputType([System.String])]
    param (
        # Registry key name/path to query.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Path')] [System.String] $Key,

        # Registry value to return.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name
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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $FilePath,

        # Arguments (if any) to apply to the process.
        [Parameter()]
        [AllowNull()]
        [System.String[]] $ArgumentList,

        # Credential to start the process as.
        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        # Working directory
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $WorkingDirectory = (Split-Path -Path $FilePath -Parent)
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
        Write-Verbose ($localized.StartingProcess -f $FilePath, $displayParams);
        if ($Credential) {
            Write-Verbose ($localized.StartingProcessAs -f $Credential.UserName);
            $startProcessParams['Credential'] = $Credential;
        }
        if ($PSCmdlet.ShouldProcess($FilePath, 'Start Process')) {
            $process = Start-Process @startProcessParams -ErrorAction Stop;
        }
        if ($PSCmdlet.ShouldProcess($FilePath, 'Wait Process')) {
            Write-Verbose ($localized.ProcessLaunched -f $process.Id);
            Write-Verbose ($localized.WaitingForProcessToExit -f $process.Id);
            $process.WaitForExit();
            $exitCode = [System.Convert]::ToInt32($process.ExitCode);
            Write-Verbose ($localized.ProcessExited -f $process.Id, $exitCode);
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
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name = 'Citrix.XenDesktop.Admin',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path = 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1'
    )
    process {

        $module = Get-ChildItem -Path $Path -Include "$Name.psd1" -File -Recurse;
        if (-not $module) {
            # If we have no .psd1 file, search for a .psm1 (for StoreFront)
            $module = Get-ChildItem -Path $Path -Include "$Name.psm1" -File -Recurse;
        }
        return $module.FullName;

    } #end process
} #end function FindModule


function TestXDModule {
<#
    .SYNOPSIS
        Tests whether Powershell modules or Snapin are available/registered.
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name = 'Citrix.XenDesktop.Admin',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path = 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1',

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $IsSnapin
    )
    process {

        if ($IsSnapin) {

            if (Get-PSSnapin -Name $Name -Registered) {
                return $true;
            }
        }
        else {

            if (FindXDModule -Name $Name -Path $Path) {
                return $true;
            }
        }

        return $false;

    } #end process
} #end TestModule


function AssertXDModule {
<#
    .SYNOPSIS
        Asserts whether all the specified modules are present, throwing if not.
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path = 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1',

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $IsSnapin
    )
    process {

        foreach ($moduleName in $Name) {

            if (-not (TestXDModule -Name $moduleName -Path $Path -IsSnapin:$IsSnapin)) {

                ThrowInvalidProgramException -ErrorId $moduleName -ErrorMessage $localized.XenDesktopSDKNotFoundError;
            }
        } #end foreach module

    } #end process
} #end function AssertXDModule


function GetXDBrokerMachine {
<#
    .SYNOPSIS
        Searches for a registered Citrix XenDesktop machine by name.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.String] $MachineName
    )
    process {

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

        if ($null -eq $brokerMachine) {

            Write-Error -ErrorId 'MachineNotFound' -Message ($localized.MachineNotFoundError -f $Machine);
            return;
        }
        elseif (($brokerMachine).Count -gt 1) {

            Write-Error -ErrorId 'AmbiguousMachineReference' -Message ($localized.AmbiguousMachineReferenceError -f $MachineName);
            return;
        }
        else {

            return $brokerMachine;
        }

    } #end process
} #end function GetXDBrokerMachine


function TestXDMachineIsExistingMember {
<#
    .SYNOPSIS
        Tests whether a machine is an existing member of a list of FQDN machine members.
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [System.String] $MachineName,

        [Parameter()]
        [System.String[]] $ExistingMembers
    )
    process {

        if ((-not $MachineName.Contains('\')) -and (-not $MachineName.Contains('.'))) {

            Write-Warning -Message ($localized.MachineNameNotFullyQualifiedWarning -f $MachineName);
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

    } #end process
} #end function TestXDMachine


function TestXDMachineMembership {
<#
    .SYNOPSIS
        Provides a centralised function to test whether machine membership of a Machine Catalog or
        Delivery Group are correct - evaluating FQDNs, DOMAINNAME\NETBIOS and NETBIOS name formats.
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [System.String[]] $RequiredMembers,

        [Parameter(Mandatory)]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure,

        [Parameter()]
        [System.String[]] $ExistingMembers
    )
    process {

        $isInCompliance = $true;

        foreach ($member in $RequiredMembers) {

            if (TestXDMachineIsExistingMember -MachineName $member -ExistingMembers $ExistingMembers) {

                if ($Ensure -eq 'Absent') {
                    Write-Verbose ($localized.SurplusMachineReference -f $member);
                    $isInCompliance = $false;
                }
            }
            else {

                if ($Ensure -eq 'Present') {
                    Write-Verbose ($localized.MissingMachineReference -f $member);
                    $isInCompliance = $false;
                }
            }

        } #end foreach member

        return $isInCompliance;

    } #end process
} #end function TestXDMachineMembers


function ResolveXDBrokerMachine {
<#
    .SYNOPSIS
        Returns a machine machine from an existing collection of Citrix XenDesktop
        machines assigned to a Machine Catalog or Delivery Group
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory)]
        [System.String] $MachineName,

        [Parameter(Mandatory)]
        [AllowNull()]
        [System.Object[]] $BrokerMachines
    )
    process {

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

    } #end process
} #end function ResolveXDBrokerMachine


function ThrowInvalidOperationException {
<#
    .SYNOPSIS
        Throws terminating error of category NotInstalled with specified errorId and errorMessage.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.String] $ErrorId,

        [Parameter(Mandatory)]
        [System.String] $ErrorMessage
    )
    process {

        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument;
        $exception = New-Object -TypeName 'System.InvalidOperationException' -ArgumentList $ErrorMessage;
        $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $exception, $ErrorId, $errorCategory, $null;
        throw $errorRecord;

    } #end process
} #end function ThrowInvalidOperationException


function ThrowInvalidProgramException {
<#
    .SYNOPSIS
        Throws terminating error of category NotInstalled with specified errorId and errorMessage.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.String] $ErrorId,

        [Parameter(Mandatory)]
        [System.String] $ErrorMessage
    )
    process {

        $errorCategory = [System.Management.Automation.ErrorCategory]::NotInstalled;
        $exception = New-Object -TypeName 'System.InvalidProgramException' -ArgumentList $ErrorMessage;
        $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $exception, $ErrorId, $errorCategory, $null;
        throw $errorRecord;

    } #end process
} #end function ThrowInvalidProgramException


function ThrowOperationCanceledException {
<#
    .SYNOPSIS
        Throws terminating error of category InvalidOperation with specified errorId and errorMessage.
#>
    param(
        [Parameter(Mandatory)]
        [System.String] $ErrorId,

        [Parameter(Mandatory)]
        [System.String] $ErrorMessage
    )
    process {

        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
        $exception = New-Object -TypeName 'System.OperationCanceledException' -ArgumentList $ErrorMessage;
        $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $exception, $ErrorId, $errorCategory, $null;
        throw $errorRecord;

    } #end process
} #end function ThrowOperationCanceledException


function TestXDInstalledRole {
<#
    .SYNOPSIS
        Tests whether a Citrix XenDesktop 7.x role is installed.
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        ## Citrix XenDesktop 7.x role to query.
        [Parameter(Mandatory)]
        [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')]
        [System.String[]] $Role
    )
    process {

        $installedRoles = GetXDInstalledRole -Role $Role;
        foreach ($r in $Role) {

            if ($installedRoles -notcontains $r) {
                return $false;
            }
        }

        return $true;

    } #end process
} #end function TestXDRole


function GetXDInstalledRole {
<#
    .SYNOPSIS
        Returns installed Citrix XenDesktop 7.x installed products.
#>
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param (
        ## Citrix XenDesktop 7.x role to query.
        [Parameter(Mandatory)]
        [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')]
        [System.String[]] $Role
    )
    process {

        $installedProducts = Get-ItemProperty 'HKLM:\SOFTWARE\Classes\Installer\Products\*' -ErrorAction SilentlyContinue |
            Where-Object { $_.ProductName -like '*Citrix*' -and $_.ProductName -notlike '*snap-in' } |
                Select-Object -ExpandProperty ProductName;

        $installedRoles = @();
        foreach ($r in $Role) {

            switch ($r) {

                'Controller' {
                    $filter = 'Citrix Broker Service';
                }
                'Studio' {
                    $filter = 'Citrix Studio';
                }
                'Storefront' {
                    $filter = 'Citrix Storefront$';
                }
                'Licensing' {
                    $filter = 'Citrix Licensing';
                }
                'Director' {
                    $filter = 'Citrix Director(?!.VDA Plugin)';
                }
                'DesktopVDA' {
                    $filter = 'Citrix Virtual Desktop Agent';
                }
                'SessionVDA' {
                    $filter = 'Citrix Virtual Desktop Agent';
                }
            }

            $result = $installedProducts -match $filter;
            if ([System.String]::IsNullOrEmpty($result)) {

            }
            elseif ($result) {
                $installedRoles += $r;
            }

        }

        return $installedRoles;

    } #end process
} #end function GetXDInstalledProduct


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
        [Parameter(Mandatory)]
        [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')]
        [System.String[]] $Role,

        ## Citrix XenDesktop 7.x installation media path.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SourcePath
    )
    process {

        $architecture = 'x86';
        if ([System.Environment]::Is64BitOperatingSystem) {
            $architecture = 'x64';
        }

        if ($Role -contains 'DesktopVDA') {
            $installMedia = 'XenDesktopVdaSetup.exe';
        }
        elseif ($Role -contains 'SessionVDA') {
            $installMedia = 'XenDesktopVdaSetup.exe';
        }
        else {
            $installMedia = 'XenDesktopServerSetup.exe';
        }

        $sourceArchitecturePath = Join-Path -Path $SourcePath -ChildPath $architecture;
        $installMediaPath = Get-ChildItem -Path $sourceArchitecturePath -Filter $installMedia -Recurse -File;

        if (-not $installMediaPath) {
            throw ($localized.NoValidSetupMediaError -f $installMedia, $sourceArchitecturePath);
        }

        return $installMediaPath.FullName;

    } #end process
} #end function ResolveXDSetupMedia


function ResolveXDServerSetupArguments {
<#
    .SYNOPSIS
        Resolve the installation arguments for the associated XenDesktop role.
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        ## Citrix XenDesktop 7.x role to install/uninstall.
        [Parameter(Mandatory)]
        [ValidateSet('Controller','Studio','Storefront','Licensing','Director')]
        [System.String[]] $Role,

        ## Citrix XenDesktop 7.x installation media path.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer'),

        ## Uninstall Citrix XenDesktop 7.x product.
        [Parameter()]
        [System.Management.Automation.SwitchParameter] $Uninstall
    )
    process {

        $arguments = New-Object -TypeName System.Collections.ArrayList -ArgumentList @();
        $arguments.AddRange(@('/QUIET', '/LOGPATH', "`"$LogPath`"", '/NOREBOOT', '/COMPONENTS'));

        $components = @();
        foreach ($r in $Role) {

            switch ($r) {
                ## Install/uninstall component names by role
                'Controller' {
                    $components += 'CONTROLLER';
                }
                'Studio' {
                    $components += 'DESKTOPSTUDIO';
                }
                'Storefront' {
                    $components += 'STOREFRONT';
                }
                'Licensing' {
                    $components += 'LICENSESERVER';
                }
                'Director' {
                    $components += 'DESKTOPDIRECTOR';
                }
            } #end switch Role
        }

        $componentString = [System.String]::Join(',', $components);
        [ref] $null = $arguments.Add($componentString);

        if ($Uninstall) {
            [ref] $null = $arguments.Add('/REMOVE');
        }
        else {
            ## Additional install parameters per role
            if ($Role -contains 'Controller') {
                [ref] $null = $arguments.Add('/NOSQL');
            }
            [ref] $null = $arguments.Add('/CONFIGURE_FIREWALL');

        }

        return [System.String]::Join(' ', $arguments.ToArray());

    } #end process
} #end function ResolveXDSetupArguments

#endregion Private Functions
