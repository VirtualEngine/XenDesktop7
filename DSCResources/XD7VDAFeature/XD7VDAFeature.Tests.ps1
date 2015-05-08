$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".");
. "$here\$sut";

## Dot source XD7Common functions
$moduleParent = Split-Path -Path $here -Parent;
Get-ChildItem -Path "$moduleParent\XD7Common" -Include *.ps1 -Exclude '*.Tests.ps1' -Recurse |
    ForEach-Object { . $_.FullName; }

Describe 'cXD7Role\ResolveXDVdaSetupArguments' {
    
    Mock -CommandName Get-WmiObject -MockWith { }
    foreach ($role in @('SessionVDA','DesktopVDA')) {

        It "$role returns default install arguments." {
            $arguments = ResolveXDVdaSetupArguments -Role $role;
            $arguments -match '/quiet' | Should Be $true;
            $arguments -match '/logpath' | Should Be $true;
            $arguments -match '/noreboot' | Should Be $true;
            $arguments -match '/components VDA' | Should Be $true;
            $arguments -match '/optimize' | Should Be $false;
            $arguments -match '/enable_hdx_ports' | Should Be $true;
            $arguments -match '/enable_real_time_transport' | Should Be $false;
            $arguments -match '/enable_remote_assistance' | Should Be $true;
        
            $arguments -match '/servervdi' | Should Be $false;
            $arguments -match '/remove' | Should Be $false;
            $arguments -match '/removeall' | Should Be $false;
        }

        It "$role returns /enable_real_time_transport argument." {
            $arguments = ResolveXDVdaSetupArguments -Role $role -EnableRealTimeTransport $true;
            $arguments -match '/enable_real_time_transport' | Should Be $true;
        }

        It "$role returns /optimize argument." {
            $arguments = ResolveXDVdaSetupArguments -Role $role -Optimize $true;
            $arguments -match '/optimize' | Should Be $true;
        }

        It "$role returns /nodesktopexperience argument." {
            $arguments = ResolveXDVdaSetupArguments -Role $role -InstallDesktopExperience $false;
            $arguments -match '/nodesktopexperience' | Should Be $true;
        }
    
        It "$role returns /components VDA,PLUGINS argument." {
            $arguments = ResolveXDVdaSetupArguments -Role $role -InstallReceiver $true;
            $arguments -match '/components VDA,PLUGINS' | Should Be $true;
        }

        It "$role returns default uninstall arguments." {
            $arguments = ResolveXDVdaSetupArguments  -Role $role -Uninstall;
            $arguments -match '/quiet' | Should Be $true;
            $arguments -match '/logpath' | Should Be $true;
            $arguments -match '/noreboot' | Should Be $true;
            $arguments -match '/components VDA' | Should Be $true;
            $arguments -match '/remove' | Should Be $true;       
        
            $arguments -match '/optimize' | Should Be $false;
            $arguments -match '/enable_hdx_ports' | Should Be $false;
            $arguments -match '/enable_real_time_transport' | Should Be $false;
            $arguments -match '/enable_remote_assistance' | Should Be $false;
            $arguments -match '/servervdi' | Should Be $false;
        }

    } #end foreach $role

    It 'DesktopVDI returns /servervdi argument on server operating system.' {
        Mock -CommandName Get-WmiObject -MockWith { return @{ Caption = 'Windows Server 2012'; }; }
        $arguments = ResolveXDVdaSetupArguments  -Role DesktopVDA;
        $arguments -match '/servervdi' | Should Be $true;
    }

} #end describe cXD7Role\ResolveXDVdaSetupArguments 
