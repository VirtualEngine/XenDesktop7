Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateSet('DesktopVDA','SessionVDA')]
        [System.String] $Role,

        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SourcePath,

        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $InstallReceiver = $false,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $EnableRemoteAssistance = $true,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $Optimize = $false,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $InstallDesktopExperience = $true,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $EnableRealTimeTransport = $false
    )
    process {
        $targetResource = @{
            Role = $Role;
            SourcePath = $SourcePath;
            InstallReceiver = $InstallReceiver;
            EnableRemoteAssistance = $EnableRemoteAssistance;
            Optimize = $Optimize;
            InstallDesktopExperience = $InstallDesktopExperience;
            EnableRealTimeTransport = $EnableRealTimeTransport;
            Ensure = 'Absent';
        }
        if (TestXDInstalledRole -Role $Role) {
            $targetResource['Ensure'] = 'Present';
        }
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateSet('DesktopVDA','SessionVDA')]
        [System.String] $Role,

        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SourcePath,

        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $InstallReceiver = $false,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $EnableRemoteAssistance = $true,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $Optimize = $false,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $InstallDesktopExperience = $true,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $EnableRealTimeTransport = $false,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer')
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($targetResource.Ensure -eq $Ensure) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $Role);
            return $true;
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $Role);
            return $false;
        }
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateSet('DesktopVDA','SessionVDA')]
        [System.String] $Role,

        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SourcePath,

        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $InstallReceiver = $false,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $EnableRemoteAssistance = $true,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $Optimize = $false,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $InstallDesktopExperience = $true,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $EnableRealTimeTransport = $false,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer')
    )
    begin {
        if (-not (Test-Path -Path $SourcePath -PathType Container)) {
            throw ($localizedData.InvalidSourcePathError -f $SourcePath);
        }
    }
    process {
        Write-Verbose ($localizedData.LogDirectorySet -f $logPath);
        Write-Verbose ($localizedData.SourceDirectorySet -f $SourcePath);
        $installMediaPath = ResolveXDSetupMedia -Role $Role -SourcePath $SourcePath;

        $resolveXDVdaSetupArgumentParams = @{
            Role = $Role;
            LogPath = $LogPath
        }
        if ($Ensure -eq 'Present') {
            Write-Verbose ($localizedData.InstallingRole -f $Role);
            $resolveXDVdaSetupArgumentParams['InstallReceiver'] = $InstallReceiver;
            $resolveXDVdaSetupArgumentParams['EnableRemoteAssistance'] = $EnableRemoteAssistance;
            $resolveXDVdaSetupArgumentParams['Optimize'] = $Optimize;
            $resolveXDVdaSetupArgumentParams['InstallDesktopExperience'] = $InstallDesktopExperience;
            $resolveXDVdaSetupArgumentParams['EnableRealTimeTransport'] = $EnableRealTimeTransport;
            $installArguments = ResolveXDVdaSetupArguments @resolveXDVdaSetupArgumentParams;
        }
        else {
            ## Uninstall
            Write-Verbose ($localizedData.UninstallingRole -f $Role);
            $resolveXDVdaSetupArgumentParams['InstallReceiver'] = $InstallReceiver;
            $installArguments = ResolveXDVdaSetupArguments @resolveXDVdaSetupArgumentParams -Uninstall;
        }
        $exitCode = StartWaitProcess -FilePath $installMediaPath -ArgumentList $installarguments -Credential $Credential;
        # The Citrix XenDesktop requires a reboot
        $global:DSCMachineStatus = 1;
    } #end process
} #end function Set-TargetResource

#region Private Functions

function ResolveXDVdaSetupArguments {
    <#
    .SYNOPSIS
        Resolve the installation arguments for the associated XenDesktop role.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        ## Citrix XenDesktop 7.x role to install/uninstall.
        [Parameter(Mandatory)] [ValidateSet('DesktopVDA','SessionVDA')]
        [System.String] $Role,

        ## Citrix XenDesktop 7.x installation media path.
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer'),

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $InstallReceiver = $false,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $EnableRemoteAssistance = $true,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $Optimize = $false,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $InstallDesktopExperience = $true,

        [Parameter()] [ValidateNotNull()]
        [System.Boolean] $EnableRealTimeTransport = $false,

        ## Uninstall Citrix XenDesktop 7.x product.
        [Parameter()]
        [System.Management.Automation.SwitchParameter] $Uninstall
    )
    process {
        $arguments = New-Object -TypeName System.Collections.ArrayList -ArgumentList @();
        $arguments.AddRange(@('/QUIET', '/LOGPATH', "`"$LogPath`"", '/NOREBOOT', '/COMPONENTS'));
        if ($InstallReceiver) {
            [ref] $null = $arguments.AddRange(@('VDA,PLUGINS'));
        }
        else {
            [ref] $null = $arguments.Add('VDA');
        }

        if ($Uninstall) {
            [ref] $null = $arguments.Add('/REMOVE');
        }
        else {
            ## Additional install parameters per role
            [ref] $null = $arguments.Add('/ENABLE_HDX_PORTS');
            if ($EnableRemoteAssistance -eq $true) {
                [ref] $null = $arguments.Add('/ENABLE_REMOTE_ASSISTANCE');
            }
            if ($Optimize) {
                [ref] $null = $arguments.Add('/OPTIMIZE');
            }
            if (-not $InstalLDesktopExperience) {
                [ref] $null = $arguments.Add('/NODESKTOPEXPERIENCE');
            }
            if ($EnableRealTimeTransport) {
                [ref] $null = $arguments.Add('/ENABLE_REAL_TIME_TRANSPORT');
            }
            if ($Role -eq 'DesktopVDA') {
                if ((Get-WmiObject -ClassName 'Win32_OperatingSystem').Caption -match 'Server') {
                    [ref] $null = $arguments.Add('/SERVERVDI');
                }
            }
        }
        return [System.String]::Join(' ', $arguments.ToArray());
    } #end process
} #end function ResolveXDServerSetupArguments

#endregion Private Functions
