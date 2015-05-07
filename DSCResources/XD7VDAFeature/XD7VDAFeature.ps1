Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateSet('DesktopVDA','SessionVDA')] [System.String] $Role, # Studio?
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SourcePath,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateNotNullOrEmpty()] [ValidateSet('Present','Absent')] $Ensure = 'Present'
    )
    process {
        $targetResource = @{
            Role = $Role;
            SourcePath = $SourcePath;
            Credential = $Credential;
            Ensure = 'Absent';
        }
        if (GetXDInstalledProduct -Role $Role) {
            $targetResource['Ensure'] = 'Present';
        }       
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateSet('DesktopVDA','SessionVDA')] [System.String] $Role,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SourcePath,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateNotNullOrEmpty()] [ValidateSet('Present','Absent')] $Ensure = 'Present'
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($Ensure -eq $targetResource.Ensure) { return $true; }
        else { return $false; }
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateSet('DesktopVDA','SessionVDA')] [System.String] $Role,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SourcePath,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateNotNullOrEmpty()] [ValidateSet('Present','Absent')] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer')
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
        if ($Ensure -eq 'Present') {
            Write-Verbose ($localizedData.InstallingRole -f $Role);
            $installArguments = ResolveXDVdaSetupArguments  -Role $Role -LogPath $LogPath;
        }
        else {
            ## Uninstall
            Write-Verbose ($localizedData.UninstallingRole -f $Role);
            $installArguments = ResolveXDVdaSetupArguments  -Role $Role -LogPath $LogPath -Uninstall;
        }
        $exitCode = StartWaitProcess -FilePath $installMediaPath -ArgumentList $installarguments -Credential $Credential;
        # Check for reboot
        if ($exitCode -eq 3010) {
            $global:DSCMachineStatus = 1;
        }
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
        [Parameter(Mandatory)] [ValidateSet('DesktopVDA','SessionVDA')] [System.String] $Role,
        ## Citrix XenDesktop 7.x installation media path.
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer'),
        ## Uninstall Citrix XenDesktop 7.x product.
        [Parameter()] [System.Management.Automation.SwitchParameter] $Uninstall
    )
    process {
        $arguments = New-Object -TypeName System.Collections.ArrayList -ArgumentList @();
        $arguments.AddRange(@('/QUIET', '/LOGPATH', "`"$LogPath`"", '/NOREBOOT', '/COMPONENTS'));
        $arguments.AddRange(@('VDA,PLUGINS'));
        
        if ($Uninstall) {
            [ref] $null = $arguments.Add('/REMOVE');
        }
        else {
            ## Additional install parameters per role
            switch ($Role) {
                { @('SessionVDA','DesktopVDA') -contains $_ } {
                    $arguments.AddRange(@('/OPTIMIZE', '/ENABLE_HDX_PORTS', '/ENABLE_REAL_TIME_TRANSPORT', '/ENABLE_REMOTE_ASSISTANCE'));
                }
                'DesktopVDA' {
                    if ((Get-WmiObject -ClassName 'Win32_OperatingSystem').Caption -match 'Server') {
                        [ref] $null = $arguments.Add('/SERVERVDI');
                    }
                }
            } #end switch Role
        }
        return [System.String]::Join(' ', $arguments.ToArray());
    } #end process
} #end function ResolveXDServerSetupArguments 

#endregion Private Functions