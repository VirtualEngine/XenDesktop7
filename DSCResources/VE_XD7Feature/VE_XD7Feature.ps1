Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director')]
        [System.String] $Role,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SourcePath,
        
        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential] $Credential,
        
        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    process {
        $targetResource = @{
            Role = $Role;
            SourcePath = $SourcePath;
            Credential = $Credential;
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
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director')]
        [System.String] $Role,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SourcePath,
        
        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential] $Credential,
        
        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',
        
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer')
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($Ensure -eq $targetResource.Ensure) {
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
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director')]
        [System.String] $Role,
        
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $SourcePath,
        
        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential] $Credential,
        
        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',
        
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer')
    )
    begin {
        if (-not (Test-Path -Path $SourcePath -PathType Container)) {
            throw ($localizedData.InvalidSourcePathError -f $SourcePath);
        }
    }
    process {
        if ($Ensure -eq 'Present') {
            Write-Verbose ($localizedData.InstallingRole -f $Role);
            $installArguments = ResolveXDServerSetupArguments -Role $Role -LogPath $LogPath;
        }
        else {
            ## Uninstall
            Write-Verbose ($localizedData.UninstallingRole -f $Role);
            $installArguments = ResolveXDServerSetupArguments -Role $Role -LogPath $LogPath -Uninstall;
        }
        Write-Verbose ($localizedData.LogDirectorySet -f $logPath);
        Write-Verbose ($localizedData.SourceDirectorySet -f $SourcePath);
        $installMediaPath = ResolveXDSetupMedia -Role $Role -SourcePath $SourcePath;
        $exitCode = StartWaitProcess -FilePath $installMediaPath -ArgumentList $installarguments -Credential $Credential;
        # Check for reboot
        if (($exitCode -eq 3010) -or ($Role -eq 'Controller')) {
            $global:DSCMachineStatus = 1;
        }
    } #end process
} #end function Set-TargetResource

#region Private Functions

function ResolveXDServerSetupArguments {
    <#
    .SYNOPSIS
        Resolve the installation arguments for the associated XenDesktop role.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        ## Citrix XenDesktop 7.x role to install/uninstall.
        [Parameter(Mandatory)] [ValidateSet('Controller','Studio','Storefront','Licensing','Director')]
        [System.String] $Role,
        
        ## Citrix XenDesktop 7.x installation media path.
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath = (Join-Path -Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer'),
        
        ## Uninstall Citrix XenDesktop 7.x product.
        [Parameter()]
        [System.Management.Automation.SwitchParameter] $Uninstall
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
            } #end switch Role
        }
        return [System.String]::Join(' ', $arguments.ToArray());
    } #end process
} #end function ResolveXDSetupArguments

#endregion Private Functions
