[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    Describe 'XenDesktop7\VE_XD7Feature' {

        Context 'Get-TargetResourece' {
            $testDrivePath = (Get-PSDrive -Name TestDrive).Root;

            It 'Returns a System.Collections.Hashtable.' {
                Mock -CommandName TestXDInstalledRole -MockWith { }
                # Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith { }
                $targetResource = Get-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Returns "Ensure" = "Present" when role is installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $true; }
                $targetResource = Get-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
                $targetResource['Ensure'] | Should Be 'Present';
            }

            It 'Returns "Ensure" = "Absent" when role is not installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $false; }
                $targetResource = Get-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
                $targetResource['Ensure'] | Should Be 'Absent';
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            $testDrivePath = (Get-PSDrive -Name TestDrive).Root;

            It 'Returns a System.Boolean type.' {
                Mock -CommandName GetXDInstalledRole -ParameterFilter { $Role -eq 'Controller' } -MockWith { }
                $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
                $targetResource -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Present" and role is installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $true; }
                $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
                $targetResource | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Present" and role is not installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $false; }
                $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Present';
                $targetResource | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Absent" and role is not installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $false; }
                $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Absent';
                $targetResource | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and role is installed' {
                Mock -CommandName TestXDInstalledRole -MockWith { return $true; }
                $targetResource = Test-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure 'Absent';
                $targetResource | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            $testDrivePath = (Get-PSDrive -Name TestDrive).Root

            It 'Throws with an invalid directory path.' {
                Mock -CommandName Test-Path -MockWith { return $false; }
                { Set-TargetResource -Role 'Controller' -SourcePath 'Z:\HopefullyThisPathNeverExists' } | Should Throw;
            }

            It 'Throws with a valid file path.' {
                [ref] $null = New-Item -Path 'TestDrive:\XenDesktopServerSetup.exe' -ItemType File;
                { Set-TargetResource -Role 'Controller' -SourcePath "$testDrivePath\XenDesktopServerSetup.exe" } | Should Throw;
            }

            foreach ($state in @('Present','Absent')) {
                It "Flags reboot when ""Ensure"" = ""$state"", ""Role"" = ""Controller"" and exit code ""0""" {
                    [System.Int32] $global:DSCMachineStatus = 0;
                    Mock -CommandName StartWaitProcess -MockWith { return 0; }
                    Mock -CommandName ResolveXDSetupMedia -MockWith { return $testDrivePath; }
                    Mock -CommandName ResolveXDServerSetupArguments -MockWith { }
                    Mock -CommandName Test-Path -MockWith { return $true; }
                    Set-TargetResource -Role 'Controller' -SourcePath $testDrivePath -Ensure $state;
                    [System.Int32] $global:DSCMachineStatus | Should Be 1;
                    Assert-MockCalled -CommandName StartWaitProcess -Exactly 1 -Scope It;
                }
            }

            foreach ($state in @('Present','Absent')) {
                foreach ($role in @('Studio','Storefront','Licensing','Director')) {
                    It "Does not flag reboot when ""Ensure"" = ""$state"", ""Role"" = ""$role"" and exit code ""0""" {
                        [System.Int32] $global:DSCMachineStatus = 0;
                        Mock -CommandName StartWaitProcess -MockWith { return 0; }
                        Mock -CommandName ResolveXDSetupMedia -MockWith { return $testDrivePath; }
                        Mock -CommandName ResolveXDServerSetupArguments -MockWith { }
                        Mock -CommandName Test-Path -MockWith { return $true; }
                        Set-TargetResource -Role $role -SourcePath $testDrivePath -Ensure $state;
                        [System.Int32] $global:DSCMachineStatus | Should Be 0;
                        Assert-MockCalled -CommandName StartWaitProcess -Exactly 1 -Scope It;
                    }
                }
            }

            foreach ($state in @('Present','Absent')) {
                foreach ($role in @('Controller','Studio','Storefront','Licensing','Director')) {
                    It "Flags reboot when ""Ensure"" = ""$state"", ""Role"" = ""$role"" and exit code = ""3010""" {
                        [System.Int32] $global:DSCMachineStatus = 0;
                        Mock -CommandName StartWaitProcess -MockWith { return 3010; }
                        Mock -CommandName ResolveXDSetupMedia -MockWith { return $testDrivePath; }
                        Mock -CommandName ResolveXDServerSetupArguments -MockWith { }
                        Mock -CommandName Test-Path -MockWith { return $true; }
                        Set-TargetResource -Role $role -SourcePath $testDrivePath -Ensure $state;
                        [System.Int32] $global:DSCMachineStatus | Should Be 1
                        Assert-MockCalled -CommandName StartWaitProcess -Exactly 1 -Scope It;
                    }
                }
            }

        } #end context Set-TargetResource
    } #end describe XD7Feature
} #end inmodulescope
