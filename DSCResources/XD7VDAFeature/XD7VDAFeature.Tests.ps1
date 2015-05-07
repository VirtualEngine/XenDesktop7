$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".");
. "$here\$sut";

## Dot source XD7Common functions
$moduleParent = Split-Path -Path $here -Parent;
Get-ChildItem -Path "$moduleParent\XD7Common" -Include *.ps1 -Exclude '*.Tests.ps1' -Recurse |
    ForEach-Object { . $_.FullName; }

Describe 'cXD7Role\ResolveXDVdaSetupArguments' {

    It 'returns expected SessionVDA install arguments.' {
        $role = 'SessionVDA';
        $arguments = ResolveXDVdaSetupArguments  -Role $role;
        $arguments -match '/quiet' | Should Be $true;
        $arguments -match '/logpath' | Should Be $true;
        $arguments -match '/noreboot' | Should Be $true;
        $arguments -match '/components VDA,Plugins' | Should Be $true;
        $arguments -match '/optimize' | Should Be $true;
        $arguments -match '/enable_hdx_ports' | Should Be $true;
        $arguments -match '/enable_real_time_transport' | Should Be $true;
        $arguments -match '/enable_remote_assistance' | Should Be $true;
        
        $arguments -match '/servervdi' | Should Be $false;
        $arguments -match '/remove' | Should Be $false;
    }

    It 'returns expected SessionVDA uninstall arguments.' {
        $role = 'SessionVDA';
        $arguments = ResolveXDVdaSetupArguments  -Role $role -Uninstall;
        $arguments -match '/quiet' | Should Be $true;
        $arguments -match '/logpath' | Should Be $true;
        $arguments -match '/noreboot' | Should Be $true;
        $arguments -match '/components VDA,Plugins' | Should Be $true;
        $arguments -match '/remove' | Should Be $true;       
        
        $arguments -match '/optimize' | Should Be $false;
        $arguments -match '/enable_hdx_ports' | Should Be $false;
        $arguments -match '/enable_real_time_transport' | Should Be $false;
        $arguments -match '/enable_remote_assistance' | Should Be $false;
        $arguments -match '/servervdi' | Should Be $false;
    }

    It 'returns expected desktop OS DesktopVDA install arguments.' {
        Mock -CommandName Get-WmiObject -MockWith { }
        $role = 'DesktopVDA';
        $arguments = ResolveXDVdaSetupArguments  -Role $role;
        $arguments -match '/quiet' | Should Be $true;
        $arguments -match '/logpath' | Should Be $true;
        $arguments -match '/noreboot' | Should Be $true;
        $arguments -match '/components VDA,Plugins' | Should Be $true;
        $arguments -match '/optimize' | Should Be $true;
        $arguments -match '/enable_hdx_ports' | Should Be $true;
        $arguments -match '/enable_real_time_transport' | Should Be $true;
        $arguments -match '/enable_remote_assistance' | Should Be $true;
        
        $arguments -match '/servervdi' | Should Be $false;
        $arguments -match '/remove' | Should Be $false;
        $arguments -match '/removeall' | Should Be $false;
    }

    It 'returns expected server OS DesktopVDA install arguments.' {
        Mock -CommandName Get-WmiObject -MockWith { return @{ Caption = 'Windows Server 2012'; }; }
        $role = 'DesktopVDA';
        $arguments = ResolveXDVdaSetupArguments  -Role $role;
        $arguments -match '/servervdi' | Should Be $true;
    }

    It 'returns expected DesktopVDA uninstall arguments.' {
        Mock -CommandName Get-WmiObject -MockWith { }
        $role = 'DesktopVDA';
        $arguments = ResolveXDVdaSetupArguments  -Role $role -Uninstall;
        $arguments -match '/quiet' | Should Be $true;
        $arguments -match '/logpath' | Should Be $true;
        $arguments -match '/noreboot' | Should Be $true;
        $arguments -match '/components VDA,Plugins' | Should Be $true;
        $arguments -match '/remove' | Should Be $true;        
        
        $arguments -match '/optimize' | Should Be $false;
        $arguments -match '/enable_hdx_ports' | Should Be $false;
        $arguments -match '/enable_real_time_transport' | Should Be $false;
        $arguments -match '/enable_remote_assistance' | Should Be $false;
        $arguments -match '/servervdi' | Should Be $false;
    }

} #end describe cXD7Role\ResolveXDVdaSetupArguments 
