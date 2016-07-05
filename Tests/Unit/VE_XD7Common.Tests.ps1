$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerMachine { }

    Describe 'XenDesktop7\VE_XD7Common' {

        Context 'AddInvokeScriptBlockCredentials' {
            $testCredential = [System.Management.Automation.PSCredential]::Empty;
            $testHashtable = @{};

            It 'Adds "ComputerName" key' {
                AddInvokeScriptBlockCredentials -Hashtable $testHashtable -Credential $testCredential;

                $testHashtable['ComputerName'] | Should Be $env:COMPUTERNAME;
            }

            It 'Adds "Authentication" key' {
                AddInvokeScriptBlockCredentials -Hashtable $testHashtable -Credential $testCredential;

                $testHashtable['Authentication'] | Should Be 'CredSSP';
            }

            It 'Adds "Credential" key' {
                AddInvokeScriptBlockCredentials -Hashtable $testHashtable -Credential $testCredential;

                $testHashtable['Credential'] | Should Be $testCredential;
            }

        } #end context AddInvokeScriptBlockCredentials

        Context 'GetXDBrokerMachine' {
            $testMachineName = 'TEST\TestMachine';
            $testMachineDnsName = 'testmachine.local';
            $testMachine = [PSCustomObject] @{ DNSName = $testMachineDnsName; MachineName = $testMachineName; }

            It 'Returns broker machine (by DNS name)' {
                Mock -CommandName Get-BrokerMachine -MockWith { return @($testMachine); }

                GetXDBrokerMachine -MachineName $testMachineDnsName | Should Not Be $null;
            }

            It 'Returns broker machine (by DomainName\NetBIOS name)' {
                Mock -CommandName Get-BrokerMachine -MockWith { return @($testMachine); }

                GetXDBrokerMachine -MachineName $testMachineName | Should Not Be $null;
            }

            It 'Returns broker machine (by NetBIOS name)' {
                Mock -CommandName Get-BrokerMachine -MockWith { return @($testMachine); }

                GetXDBrokerMachine -MachineName $testMachineName.Split('\')[1] | Should Not Be $null;
            }

            It 'Throws when no broker machine is found' {
                Mock -CommandName Get-BrokerMachine -MockWith { }

                { GetXDBrokerMachine -MachineName $testMachineName -ErrorAction Stop } | Should Throw;
            }

            It 'Throws when multiple broker machines are found' {
                Mock -CommandName Get-BrokerMachine -MockWith { return @($testMachine, $testMachine); }

                { GetXDBrokerMachine -MachineName $testMachineName -ErrorAction Stop } | Should Throw;
            }

        } #end context GetXDBrokerMachine

        Context 'TestXDMachineIsExistingMember' {
            $testMachineName = 'TEST\TestMachine1';
            $testMachineDnsName = 'testmachine1.local';

            It 'Returns True when member is present (by DNS name)' {
                $members = @('testmachine1.local','testmachine2.local');

                TestXDMachineIsExistingMember -MachineName $testMachineDnsName -ExistingMembers $members | Should Be $true;
            }

            It 'Returns True when member is present (by DomainName\NetBios name)' {
                $members = @('testmachine1.local','testmachine2.local');

                TestXDMachineIsExistingMember -MachineName $testMachineName -ExistingMembers $members | Should Be $true;
            }

            It 'Returns True when existing member is present (by NetBIOS name)' {
                $members = @('testmachine1.local','testmachine2.local');

                TestXDMachineIsExistingMember -MachineName $testMachineName.Split('\')[1] -ExistingMembers $members -WarningAction SilentlyContinue | Should Be $true;
            }

            It 'Returns False when member is absent (by DNS name)' {
                $members = @('testmachine2.local','testmachine3.local');

                TestXDMachineIsExistingMember -MachineName $testMachineDnsName -ExistingMembers $members | Should Be $false;
            }

            It 'Returns False when member is absent (by DomainName\NetBios name)' {
                $members = @('testmachine2.local','testmachine3.local');

                TestXDMachineIsExistingMember -MachineName $testMachineName -ExistingMembers $members | Should Be $false;
            }

            It 'Returns False when member is absent (by NetBIOS name)' {
                $members = @('testmachine2.local','testmachine3.local');

                TestXDMachineIsExistingMember -MachineName $testMachineName.Split('\')[1] -ExistingMembers $members -WarningAction SilentlyContinue | Should Be $false;
            }

        } #end context TestXDMachineIsExistingMember

        Context 'TestXDMachineMembership' {

            It 'Returns True when "Ensure" = "Present" and members are present (by DNS name)' {
                $requiredMembers = @('testmachine1.local','testmachine2.local');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Present | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Present" and members are present (by DomainName\NetBIOS name)' {
                $requiredMembers = @('TEST\TestMachine1','TEST\TestMachine2');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Present | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Present" and members are present (by NetBIOS name)' {
                $requiredMembers = @('TestMachine1','TestMachine2');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Present -WarningAction SilentlyContinue | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Present" and members are absent by DNS name' {
                $requiredMembers = @('testmachine1.local','testmachine3.local','testmachine2.local');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Present | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Present" and members are absent (by DomainName\NetBIOS name)' {
                $requiredMembers = @('TEST\TestMachine1','TEST\TestMachine3','TEST\TestMachine2');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Present | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Present" and members are absent (by NetBIOS name)' {
                $requiredMembers = @('TestMachine1','TestMachine3','TestMachine2');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Present -WarningAction SilentlyContinue | Should Be $false;
            }

            It 'Returns True when "Ensure" = "Absent" and members are absent (by DNS name)' {
                $requiredMembers = @('testmachine3.local');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Absent | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and members are absent (by DomainName\NetBIOS name)' {
                $requiredMembers = @('TEST\TestMachine3','TEST\TestMachine4');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Absent | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and members are absent (by NetBIOS name)' {
                $requiredMembers = @('TestMachine3','TestMachine4');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Absent -WarningAction SilentlyContinue | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Absent" and members are present (by DNS name)' {
                $requiredMembers = @('testmachine1.local');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Absent | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Absent" and members are present by (DomainName\NetBIOS name)' {
                $requiredMembers = @('TEST\TestMachine3','TEST\TestMachine2');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Absent | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Absent" and members are present (by NetBIOS name)' {
                $requiredMembers = @('TestMachine2','TestMachine3');
                $existingMembers = @('testmachine2.local','testmachine1.local');

                TestXDMachineMembership -RequiredMembers $requiredMembers -ExistingMembers $existingMembers -Ensure Absent -WarningAction SilentlyContinue | Should Be $false;
            }

        } #end context TestXDMachineMembership

        Context 'ResolveXDBrokerMachine' {

            It 'Returns a broker machine when present (by DNS Name)' {
                $brokerMachines = @(
                    @{ MachineName = 'TEST\TestMachine1'; DNSName = 'testmachine1.local'; }
                    @{ MachineName = 'TEST\TestMachine2'; DNSName = 'testmachine2.local'; }
                )

                ResolveXDBrokerMachine -MachineName testmachine1.local -BrokerMachines $brokerMachines | Should Not Be $null;
            }

            It 'Returns a broker machine when present (by DomainName\NetBIOS Name)' {
                $brokerMachines = @(
                    @{ MachineName = 'TEST\TestMachine1'; DNSName = 'testmachine1.local'; }
                    @{ MachineName = 'TEST\TestMachine2'; DNSName = 'testmachine2.local'; }
                )

                ResolveXDBrokerMachine -MachineName TEST\testmachine2 -BrokerMachines $brokerMachines | Should Not Be $null;
            }

            It 'Returns a broker machine when present (by NetBIOS Name)' {
                $brokerMachines = @(
                    @{ MachineName = 'TEST\TestMachine1'; DNSName = 'testmachine1.local'; }
                    @{ MachineName = 'TEST\TestMachine2'; DNSName = 'testmachine2.local'; }
                )

                ResolveXDBrokerMachine -MachineName testmachine1 -BrokerMachines $brokerMachines | Should Not Be $null;
            }

            It 'Returns $null when broker machine is absent (by DNS Name)' {
                $brokerMachines = @(
                    @{ MachineName = 'TEST\TestMachine1'; DNSName = 'testmachine1.local'; }
                    @{ MachineName = 'TEST\TestMachine2'; DNSName = 'testmachine2.local'; }
                )

                ResolveXDBrokerMachine -MachineName testmachine3.local -BrokerMachines $brokerMachines | Should Be $null;
            }

            It 'Returns $null when broker machine is absent (by DomainName\NetBIOS Name)' {
                $brokerMachines = @(
                    @{ MachineName = 'TEST\TestMachine1'; DNSName = 'testmachine1.local'; }
                    @{ MachineName = 'TEST\TestMachine2'; DNSName = 'testmachine2.local'; }
                )

                ResolveXDBrokerMachine -MachineName TEST\testmachine4 -BrokerMachines $brokerMachines | Should Be $null;
            }

            It 'Returns $null when broker machine is absent (by NetBIOS Name)' {
                $brokerMachines = @(
                    @{ MachineName = 'TEST\TestMachine1'; DNSName = 'testmachine1.local'; }
                    @{ MachineName = 'TEST\TestMachine2'; DNSName = 'testmachine2.local'; }
                )

                ResolveXDBrokerMachine -MachineName testmachine5 -BrokerMachines $brokerMachines | Should Be $null;
            }

        } #end context ResolveXDBrokerMachine

        Context 'GetXDInstalledRole' {
            $roles = @(
                @{ Role = 'Controller'; ProductName = 'Citrix Broker Service'; }
                @{ Role = 'Studio'; ProductName = 'Citrix Studio'; }
                @{ Role = 'Storefront'; ProductName = 'Citrix Storefront'; }
                @{ Role = 'Licensing'; ProductName = 'Citrix Licensing'; }
                @{ Role = 'Director'; ProductName = 'Citrix Director'; }
                @{ Role = 'SessionVDA'; ProductName = 'Citrix Virtual Desktop Agent'; }
                @{ Role = 'DesktopVDA'; ProductName = 'Citrix Virtual Desktop Agent'; }
            )

            foreach ($role in $roles) {

                It "Returns role ""$($role.Role)"" is installed" {
                    $getItemProperty = @(
                        ## Needs multiple Citrix* products to keep the pipeline alive
                        [PSCustomObject] @{ Role = $role.role; ProductName = $role.ProductName; },
                        [PSCustomObject] @{ Role = 'Citrix Other Product'; ProductName = 'Citrix Other Product'; }
                    );
                    Mock -CommandName Get-ItemProperty -MockWith { return $getItemProperty; }

                    GetXDInstalledRole -Role $role.Role -Verbose | Should Be $role.Role;
                }

            }

            foreach ($role in $roles) {

                It "Does not return role ""$($role.Role)"" is installed" {
                    $getItemProperty = @(
                        ## Needs multiple Citrix* products to keep the pipeline alive
                        [PSCustomObject] @{ Role = 'Citrix New Product'; ProductName = 'Citrix New Product snap-in'; },
                        [PSCustomObject] @{ Role = 'Citrix Other Product'; ProductName = 'Citrix Other Product'; }
                    );
                    Mock -CommandName Get-ItemProperty -MockWith { return $getItemProperty; }

                    GetXDInstalledRole -Role $role.Role -Verbose | Should BeNullOrEmpty;
                }

            }

            It 'Returns False when "Director" is not installed, but the VDA is installed' {
                $getItemProperty = @(
                    ## Needs multiple Citrix* products to keep the pipeline alive
                    [PSCustomObject] @{ Role = 'SessionVDA'; ProductName = 'Citrix Director VDA Plugin'; },
                    [PSCustomObject] @{ Role = 'Citrix Other Product'; ProductName = 'Citrix Other Product'; }
                );
                Mock -CommandName Get-ItemProperty -MockWith { return $getItemProperty; }

                GetXDInstalledRole -Role 'Director' | Should BeNullOrEmpty;
            }
        } #end context GetXDInstalledRole

        Context 'TestXDInstalledRole' {

            It "Returns true when when specified single role is installed" {
                $roles = 'Licensing';
                Mock -CommandName GetXDInstalledRole -MockWith { return $roles; }

                TestXDInstalledRole -Role $roles | Should Be $true;
            }

            It "Returns true when when specified multiple roles are installed" {
                $roles = 'Controller','Studio';
                Mock -CommandName GetXDInstalledRole -MockWith { return $roles; }

                TestXDInstalledRole -Role $roles | Should Be $true;
            }

            It "Returns false when when specified single role is not installed" {
                $roles = 'Licensing';
                Mock -CommandName GetXDInstalledRole -MockWith { return @(); }

                TestXDInstalledRole -Role $roles | Should Be $false;
            }

            It "Returns false when when specified multiple roles are not installed" {
                $roles = 'Controller','Studio';
                Mock -CommandName GetXDInstalledRole -MockWith { return @(); }

                TestXDInstalledRole -Role $roles | Should Be $false;
            }

            It "Returns false when when specified single role is not installed" {
                $roles = 'Licensing';
                Mock -CommandName GetXDInstalledRole -MockWith { return @('Director'); }

                TestXDInstalledRole -Role $roles | Should Be $false;
            }

           It "Returns false when when one of specified multiple roles are not installed" {
                $roles = 'Controller','Studio';
                Mock -CommandName GetXDInstalledRole -MockWith { return @('Studio'); }

                TestXDInstalledRole -Role $roles | Should Be $false;
            }

        } #end context TestXDInstalledRole

        Context 'ResolveXDSetupMedia' {
            $testDrivePath = (Get-PSDrive -Name TestDrive).Root
            [ref] $null = New-Item -Path 'TestDrive:\x86\Xen Desktop Setup' -ItemType Directory;
            [ref] $null = New-Item -Path 'TestDrive:\x86\Xen Desktop Setup\XenDesktopServerSetup.exe' -ItemType File;
            [ref] $null = New-Item -Path 'TestDrive:\x86\Xen Desktop Setup\XenDesktopVdaSetup.exe' -ItemType File;
            [ref] $null = New-Item -Path 'TestDrive:\x64\Xen Desktop Setup' -ItemType Directory;
            [ref] $null = New-Item -Path 'TestDrive:\x64\Xen Desktop Setup\XenDesktopServerSetup.exe' -ItemType File;
            [ref] $null = New-Item -Path 'TestDrive:\x64\Xen Desktop Setup\XenDesktopVdaSetup.exe' -ItemType File;

            $architecture = 'x86';
            if ([System.Environment]::Is64BitOperatingSystem) { $architecture = 'x64' }

            foreach ($role in @('Controller','Studio','Licensing','Director','Storefront')) {

                It "Resolves ""$role"" role setup to ""XenDesktopServerSetup.exe""." {
                    $setup = ResolveXDSetupMedia -Role $role -SourcePath $testDrivePath;

                    $setup.EndsWith('XenDesktopServerSetup.exe') | Should Be $true;
                    $setup.Contains($architecture) | Should Be $true;
                }

            }

            It 'Throws when no valid installer found.' {
                [ref] $null = New-Item -Path 'TestDrive:\Empty' -ItemType Directory;

                { ResolveXDSetupMedia -Role $role -SourcePath "$testDrivePath\Empty" } | Should Throw;
            }

        } #end context ResolveXDSetupMedia

        Context 'ResolveXDServerSetupArguments' {

            It 'Defaults log path to "%TMP%\Citrix\XenDesktop Installer".' {
                $role = 'Controller';
                $arguments = ResolveXDServerSetupArguments  -Role $role;
                $arguments -match '/logpath' | Should Be $true;
                $escapedPathRegex = (Join-Path $env:TMP -ChildPath '\Citrix\XenDesktop Installer').Replace('\', '\\');
                $arguments -match $escapedPathRegex | Should Be $true;
            }

            It 'Returns expected Controller install arguments.' {
                $role = 'Controller';
                $arguments = ResolveXDServerSetupArguments  -Role $role;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components Controller' | Should Be $true;
                $arguments -match '/configure_firewall' | Should Be $true;
                $arguments -match '/nosql' | Should Be $true;

                $arguments -match '/remove' | Should Be $false;
            }

            It 'Returns expected Controller uninstall arguments.' {
                $role = 'Controller';
                $arguments = ResolveXDServerSetupArguments  -Role $role -Uninstall;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components Controller' | Should Be $true;
                $arguments -match '/remove' | Should Be $true;

                $arguments -match '/configure_firewall' | Should Be $false;
                $arguments -match '/nosql' | Should Be $false;
            }

            It 'Returns expected Studio install arguments.' {
                $role = 'Studio';
                $arguments = ResolveXDServerSetupArguments  -Role $role;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components DesktopStudio' | Should Be $true;
                $arguments -match '/configure_firewall' | Should Be $true;

                $arguments -match '/remove' | Should Be $false;
            }

            It 'Returns expected Studio uninstall arguments.' {
                $role = 'Studio';
                $arguments = ResolveXDServerSetupArguments  -Role $role -Uninstall;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components DesktopStudio' | Should Be $true;
                $arguments -match '/remove' | Should Be $true;

                $arguments -match '/configure_firewall' | Should Be $false;
            }

            It 'Returns expected Storefront install arguments.' {
                $role = 'Storefront';
                $arguments = ResolveXDServerSetupArguments  -Role $role;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components Storefront' | Should Be $true;
                $arguments -match '/configure_firewall' | Should Be $true;

                $arguments -match '/remove' | Should Be $false;
            }

            It 'Returns expected Storefront uninstall arguments.' {
                $role = 'Storefront';
                $arguments = ResolveXDServerSetupArguments  -Role $role -Uninstall;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components Storefront' | Should Be $true;
                $arguments -match '/remove' | Should Be $true;

                $arguments -match '/configure_firewall' | Should Be $false;
            }

            It 'Returns expected Licensing install arguments.' {
                $role = 'Licensing';
                $arguments = ResolveXDServerSetupArguments  -Role $role;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components LicenseServer' | Should Be $true;
                $arguments -match '/configure_firewall' | Should Be $true;

                $arguments -match '/remove' | Should Be $false;
            }

            It 'Returns expected Licensing uninstall arguments.' {
                $role = 'Licensing';
                $arguments = ResolveXDServerSetupArguments  -Role $role -Uninstall;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components LicenseServer' | Should Be $true;
                $arguments -match '/remove' | Should Be $true;

                $arguments -match '/configure_firewall' | Should Be $false;
            }

            It 'Returns expected Director install arguments.' {
                $role = 'Director';
                $arguments = ResolveXDServerSetupArguments  -Role $role;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components DesktopDirector' | Should Be $true;
                $arguments -match '/configure_firewall' | Should Be $true;

                $arguments -match '/remove' | Should Be $false;
            }

            It 'Returns expected Director uninstall arguments.' {
                $role = 'Director';
                $arguments = ResolveXDServerSetupArguments  -Role $role -Uninstall;
                $arguments -match '/quiet' | Should Be $true;
                $arguments -match '/logpath' | Should Be $true;
                $arguments -match '/noreboot' | Should Be $true;
                $arguments -match '/components DesktopDirector' | Should Be $true;
                $arguments -match '/remove' | Should Be $true;

                $arguments -match '/configure_firewall' | Should Be $false;
            }

        } #end context ResolveXDServerSetupArguments

    } #end describe cXD7Role\ResolveXDSetupMedia

} #end inmodulescope

<# FROM: xXD7Feature\Get-TargetResource
    It 'returns input role, source path and credentials.' {
        $role = 'Controller';
        $credential = New-Object System.Management.Automation.PSCredential 'Username', (ConvertTo-SecureString -String 'Password' -AsPlainText -Force);
        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith { }
        $targetResource = Get-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present' -Credential $credential;
        $targetResource.Role | Should Be $role;
        $targetResource.SourcePath | Should Be $testDrivePath;
        $targetResource.Credential | Should Be $credential;
    }

    It 'returns Controller role is present.' {
        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith {
            return @{ Name = 'Citrx Desktop Delivery Controller'; };
        }
        $targetResource = Get-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
        $targetResource.Ensure | Should Be 'Present';
    }

    It 'returns Controller role is absent.' {
        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith { }
        $targetResource = Get-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
        $targetResource.Ensure | Should Be 'Absent';
    }

    It 'returns Desktop Studio role is present.' {
        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Studio' } -MockWith {
            return @{ Name = 'Citrx Studio'; };
        }
        $targetResource = Get-TargetResource -Role 'Studio' -SourcePath $testDrivePath -Ensure 'Present';
        $targetResource.Ensure | Should Be 'Present';
    }

    It 'returns Desktop Studio role is absent.' {
        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Studio' } -MockWith { }
        $targetResource = Get-TargetResource -Role 'Studio' -SourcePath $testDrivePath -Ensure 'Present';
        $targetResource.Ensure | Should Be 'Absent';
    }
#>

<# FROM: xXD7Feature\Test-TargetResource
    It 'returns Controller role is installed when it should be.' {
        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith {
            return @{ Name = 'Citrx Desktop Delivery Controller'; };
        }
        $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
        $targetResource | Should Be $true;
    }

    It 'returns Controller role is not installed when it should be.' {
        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith { }
        $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
        $targetResource | Should Be $false;
    }

    It 'returns Controller role is not installed when it should not be.' {
        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith { }
        $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Absent';
        $targetResource | Should Be $true;
    }

    It 'returns Controller role is installed when it should not be.' {

        Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith {
            return @{ Name = 'Citrx Desktop Delivery Controller'; };
        }
        $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Absent';
        $targetResource | Should Be $false;
    }
#>
