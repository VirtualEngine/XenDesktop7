[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    Describe 'XenDesktop7\VE_XD7VDAFeature' {

        Context 'ResolveXDVdaSetupArguments' {
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
                Mock -CommandName Get-CimInstance -MockWith { return @{ Caption = 'Windows Server 2012'; }; }

                $arguments = ResolveXDVdaSetupArguments  -Role DesktopVDA;

                $arguments -match '/servervdi' | Should Be $true;
            }

        } #end context ResolveXDVdaSetupArguments

        Context 'Get-TargetResourece' {
            $testDrivePath = (Get-PSDrive -Name TestDrive).Root;

            It 'Returns a System.Collections.Hashtable.' {
                Mock -CommandName TestXDInstalledRole -MockWith { }

                $targetResource = Get-TargetResource -Role 'DesktopVDA' -SourcePath $testDrivePath -Ensure 'Present';

                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            foreach ($role in @('SessionVDA','DesktopVDA')) {

                It "Returns ""Ensure"" = ""Present"" when ""$role"" role is installed" {
                    Mock -CommandName TestXDInstalledRole -MockWith { return $true; }

                    $targetResource = Get-TargetResource -Role $role -SourcePath $testDrivePath;

                    $targetResource['Ensure'] | Should Be 'Present';
                }

                It "Returns ""Ensure"" = ""Absent"" when ""$role"" role is not installed" {
                    Mock -CommandName TestXDInstalledRole -MockWith { return $false; }

                    $targetResource = Get-TargetResource -Role $role -SourcePath $testDrivePath;

                    $targetResource['Ensure'] | Should Be 'Absent';
                }

            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            $testDrivePath = (Get-PSDrive -Name TestDrive).Root;

            ## Ensure secure boot is not triggered
            Mock Confirm-SecureBootUEFI -MockWith { return $false; }

            It 'Returns a System.Boolean type.' {
                Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'DesktopVDA' } -MockWith { }

                $targetResource = Test-TargetResource -Role 'DesktopVDA' -SourcePath $testDrivePath -Ensure 'Present';

                $targetResource -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Present" and role is installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $true; }

                $targetResource = Test-TargetResource -Role 'DesktopVDA' -SourcePath $testDrivePath -Ensure 'Present';

                $targetResource | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Present" and role is not installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $false; }

                $targetResource = Test-TargetResource -Role 'DesktopVDA' -SourcePath $testDrivePath -Ensure 'Present';

                $targetResource | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Absent" and role is not installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $false; }

                $targetResource = Test-TargetResource -Role 'DesktopVDA' -SourcePath $testDrivePath -Ensure 'Absent';

                $targetResource | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and role is installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $true; }

                $targetResource = Test-TargetResource -Role 'DesktopVDA' -SourcePath $testDrivePath -Ensure 'Absent';

                $targetResource | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            $testDrivePath = (Get-PSDrive -Name TestDrive).Root

            It 'Throws with an invalid directory path.' {
                Mock -CommandName Test-Path -MockWith { return $false; }

                { Set-TargetResource -Role 'DesktopVDA' -SourcePath 'Z:\HopefullyThisPathNeverExists' } | Should Throw;
            }

            It 'Throws with a valid file path.' {
                [ref] $null = New-Item -Path 'TestDrive:\XenDesktopServerSetup.exe' -ItemType File;

                { Set-TargetResource -Role 'DesktopVDA' -SourcePath "$testDrivePath\XenDesktopServerSetup.exe" } | Should Throw;
            }

            foreach ($state in @('Present','Absent')) {
                foreach ($role in @('DesktopVDA','SessionVDA')) {
                    foreach ($exitCode in @(0, 3010)) {
                        It "Flags reboot when ""Ensure"" = ""$state"", ""Role"" = ""$role"" and exit code = ""$exitCode""" {
                            [System.Int32] $global:DSCMachineStatus = 0;
                            Mock -CommandName StartWaitProcess -MockWith { return $exitCode; }
                            Mock -CommandName ResolveXDSetupMedia -MockWith { return $testDrivePath; }
                            Mock -CommandName ResolveXDVdaSetupArguments -MockWith { }
                            Mock -CommandName Test-Path -MockWith { return $true; }

                            Set-TargetResource -Role $role -SourcePath $testDrivePath -Ensure $state;

                            [System.Int32] $global:DSCMachineStatus | Should Be 1
                            Assert-MockCalled -CommandName StartWaitProcess -Exactly 1 -Scope It;
                        }
                    }
                }
            }

        } #end context Set-TargetResource


    } #end describe XD7VDAFeature
} #end inmodulescope
