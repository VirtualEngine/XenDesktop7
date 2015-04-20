Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')] [System.String] $Role, # Studio?
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
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')] [System.String] $Role,
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
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')] [System.String] $Role,
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
            $installArguments = ResolveXDSetupArguments -Role $Role -LogPath $LogPath;
        }
        else {
            ## Uninstall
            Write-Verbose ($localizedData.UninstallingRole -f $Role);
            $installArguments = ResolveXDSetupArguments -Role $Role -LogPath $LogPath -Uninstall;
        }
        $exitCode = StartWaitProcess -FilePath $installMediaPath -ArgumentList $installarguments -Credential $Credential;
        # Check for reboot
        if ($exitCode -eq 3010) {
            $global:DSCMachineStatus = 1;
        }
    } #end process
} #end function Set-TargetResource

#region Private Functions

function GetXDInstalledProduct {
    <#
    .SYNOPSIS
        Returns installed XD product by role.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Win32.RegistryKey])]
    param (
        ## Citrix XenDesktop 7.x role to install/uninstall.
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')] [System.String] $Role
    )
    process {
        switch ($Role) {
            'Controller' { $wmiFilter = 'Citrix Broker Service'; }
            'Studio' { $wmiFilter = 'Citrix Studio'; }
            'Storefront' { $wmiFilter = 'Citrix Storefront'; }
            'Licensing' { $wmiFilter = 'Citrix Licensing'; }
            'Director' { $wmiFilter = 'Citrix Director'; }
            'DesktopVDA' { $wmiFilter = 'Citrix Virtual Desktop Agent'; }
            'SessionVDA' { $wmiFilter = 'Citrix Virtual Desktop Agent'; } # Name: Citrix Virtual Delivery Agent 7.6, DisplayName: Citrix Virtual Desktop Agent?
        }
        return Get-WmiObject -Class 'Win32_Product' -Filter "Name Like '%$wmiFilter%'";
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

function ResolveXDSetupArguments {
    <#
    .SYNOPSIS
        Resolve the installation arguments for the associated
        XenDesktop role.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        ## Citrix XenDesktop 7.x role to install/uninstall.
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director','DesktopVDA','SessionVDA')] [System.String] $Role,
        ## Citrix XenDesktop 7.x installation media path.
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer'),
        ## Uninstall Citrix XenDesktop 7.x product.
        [Parameter()] [System.Management.Automation.SwitchParameter] $Uninstall
    )
    process {
        $arguments = New-Object -TypeName System.Collections.ArrayList -ArgumentList @();
        $arguments.AddRange(@('/QUIET', '/LOGPATH', "`"$LogPath`"", '/NOREBOOT', '/COMPONENTS'));
        switch ($Role) {
            ## Install/uninstall component names by role
            'Controller' { [ref] $null = $arguments.Add('CONTROLLER'); }
            'Studio' { [ref] $null = $arguments.Add('DESKTOPSTUDIO'); }
            'Storefront' { [ref] $null = $arguments.Add('STOREFRONT'); }
            'Licensing' { [ref] $null = $arguments.Add('LICENSESERVER'); }
            'Director' { [ref] $null = $arguments.Add('DESKTOPDIRECTOR'); }
            { @('SessionVDA','DesktopVDA') -contains $_ } { $arguments.AddRange(@('VDA,PLUGINS')); }
        } #end switch Role
        
        if ($Uninstall) {
            [ref] $null = $arguments.Add('/REMOVE');
        }
        else {
            ## Additional install parameters per role
            switch ($Role) {
                'Controller' { $arguments.AddRange(@('/CONFIGURE_FIREWALL', '/NOSQL')); }
                'Studio' { $arguments.AddRange(@('/CONFIGURE_FIREWALL')); }
                'Storefront' { $arguments.AddRange(@('/CONFIGURE_FIREWALL')); }
                'Licensing' { $arguments.AddRange(@('/CONFIGURE_FIREWALL')); }
                'Director' { };
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
} #end function ResolveXDSetupArguments

#endregion Private Functions