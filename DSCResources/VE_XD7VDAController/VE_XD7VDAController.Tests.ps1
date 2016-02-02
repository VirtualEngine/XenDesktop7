$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'VE_XD7VDAController' {

    Describe 'VE_XD7VDAController' {
    
        Context 'Test-TargetResource' {
        
            It 'Returns True when "Ensure" = "Present" and DDC exists with single DDC.' {
                Mock -CommandName GetRegistryValue -MockWith { return 'ddc1'; }
                Test-TargetResource -Name 'ddc1' -Ensure 'Present' | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Present" and DDC exists with mulitple DDCs.' {
                Mock -CommandName GetRegistryValue -MockWith { return 'ddc1 ddc2'; }
                Test-TargetResource -Name 'ddc1' -Ensure 'Present' | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Present" and DDC does not exist with single DDCs.' {
                Mock -CommandName GetRegistryValue -MockWith { return 'ddc2'; }
                Test-TargetResource -Name 'ddc1' -Ensure 'Present' | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Present" and DDC does not exist with mulitple DDCs.' {
                Mock -CommandName GetRegistryValue -MockWith { return 'ddc1 ddc2'; }
                Test-TargetResource -Name 'ddc3' -Ensure 'Present' | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Absent" and DDC exists with single DDC.' {
                Mock -CommandName GetRegistryValue -MockWith { return 'ddc1'; }
                Test-TargetResource -Name 'ddc1' -Ensure 'Absent' | Should Be $false;
            }

            It 'Returns False when "Ensure" = "Absent" and DDC exists with mulitple DDCs.' {
                Mock -CommandName GetRegistryValue -MockWith { return 'ddc1 ddc2'; }
                Test-TargetResource -Name 'ddc1' -Ensure 'Absent' | Should Be $false;
            }

            It 'Returns True when "Ensure" = "Absent" and DDC does not exist with single DDCs.' {
                Mock -CommandName GetRegistryValue -MockWith { return 'ddc2'; }
                Test-TargetResource -Name 'ddc1' -Ensure 'Absent' | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and DDC does not exist with mulitple DDCs.' {
                Mock -CommandName GetRegistryValue -MockWith { return 'ddc1 ddc2'; }
                Test-TargetResource -Name 'ddc3' -Ensure 'Absent' | Should Be $true;
            }
        
        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName Restart-Service -ParameterFilter { $Name -eq 'BrokerAgent' } -MockWith { }
            

            It 'Calls "Set-ItemProperty" with DDC when name "Ensure" = "Present"' {
                Mock -CommandName Set-ItemProperty -ParameterFilter { $Value -like '*DDC3*' } -MockWith { }
                Mock -CommandName GetRegistryValue -MockWith { return @('DDC1','DDC2'); }
                Set-TargetResource -Name DDC3;
                Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter { $Value -like '*DDC3*' } -Exactly 1 -Scope It;
            }

            It 'Calls "Restart-Service" when "Ensure" = "Present"' {
                Mock -CommandName Set-ItemProperty -MockWith { }
                Mock -CommandName GetRegistryValue -MockWith { return @('DDC1','DDC2'); }
                Set-TargetResource -Name DDC3;
                Assert-MockCalled -CommandName Restart-Service -ParameterFilter { $Name -eq 'BrokerAgent' } -Exactly 1 -Scope It;
            }

            It 'Calls "Set-ItemProperty" without DDC when name "Ensure" = "Absent"' {
                Mock -CommandName Set-ItemProperty -ParameterFilter { $Value -notlike '*DDC1*' } -MockWith { }
                Mock -CommandName GetRegistryValue -MockWith { return @('DDC1','DDC2'); }
                Set-TargetResource -Name DDC1 -Ensure Absent;
                Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter { $Value -notlike '*DDC1*' } -Exactly 1 -Scope It;
            }

            It 'Calls "Restart-Service" when "Ensure" = "Absent"' {
                Mock -CommandName Set-ItemProperty -MockWith { }
                Mock -CommandName GetRegistryValue -MockWith { return @('DDC1','DDC2'); }
                Set-TargetResource -Name DDC1 -Ensure Absent;
                Assert-MockCalled -CommandName Restart-Service -ParameterFilter { $Name -eq 'BrokerAgent' } -Exactly 1 -Scope It;
            }
        }

    } #end describe XD7VDAController
} #end inmodulescope
