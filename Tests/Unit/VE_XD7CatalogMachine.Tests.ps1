[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerCatalog { }
    function Get-BrokerMachine { }
    function New-BrokerMachine { }
    function Remove-BrokerMachine { }

    Describe 'XenDesktop7\VE_XD7CatalogMachine' {

        $testMachineCatalogName = 'TestGroup';
        $testMachineCatalogMembers = @('TestMachine.local');
        $testMachineCatalog = @{ Name = $testMachineCatalogName; Members = $testMachineCatalogMembers; Ensure = 'Present'; }
        $testMachineCatalogAbsent = @{ Name = $testMachineCatalogName; Members = $testMachineCatalogMembers; Ensure = 'Absent'; }
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };
            Mock -CommandName Add-PSSnapin -MockWith { };
            Mock -CommandName InvokeScriptBlock -MockWith { & $ScriptBlock; };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerMachine { }

                (Get-TargetResource @testMachineCatalog) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {

                Get-TargetResource @testMachineCatalog;

                Assert-MockCalled InvokeScriptBlock -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                $testMachineCatalogWithCredential = $testMachineCatalog.Clone();
                $testMachineCatalogWithCredential['Credential'] = $testCredential;
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }

                Get-TargetResource @testMachineCatalogWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" snapin is registered' {
                Mock -CommandName AssertXDModule -MockWith { };

                Get-TargetResource @testMachineCatalog;

                Assert-MockCalled AssertXDModule -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            It 'Returns a System.Boolean type' {
                Mock -CommandName TestXDMachineMembership -MockWith { return $true; }
                Mock -CommandName Get-TargetResource -MockWith { return $testMachineCatalog; }

                (Test-TargetResource @testMachineCatalog) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when catalog membership is correct' {
                Mock -CommandName TestXDMachineMembership -MockWith { return $true; }
                Mock -CommandName Get-TargetResource -MockWith { return $testMachineCatalog; }

                Test-TargetResource @testMachineCatalog | Should Be $true;
            }

            It 'Returns False when catalog membership is incorrect' {
                Mock -CommandName TestXDMachineMembership -MockWith { return $false; }
                Mock -CommandName Get-TargetResource -MockWith { return $testMachineCatalog; }

                Test-TargetResource @testMachineCatalog | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };
            Mock -CommandName Import-Module -MockWith { }
            Mock -CommandName Add-PSSnapin -MockWith { };
            Mock -CommandName Get-BrokerCatalog -MockWith { return @{ Name = $testCatalogName; Uid = 1; }; }
            Mock -CommandName InvokeScriptBlock -MockWith { & $ScriptBlock; };

            It 'Calls "New-BrokerMachine" when "Ensure" = "Present" and machine is registered, but not assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return [PSCustomObject] @{ CatalogName = $null }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName New-BrokerMachine -MockWith { }

                Set-TargetResource @testMachineCatalog;

                Assert-MockCalled -CommandName New-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Does not call "New-BrokerMachine" when "Ensure" = "Present" and machine is registered and assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = $testMachineCatalogName; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName New-BrokerMachine -MockWith { }

                Set-TargetResource @testMachineCatalog;

                Assert-MockCalled -CommandName New-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Calls "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is registered and assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = $testMachineCatalogName; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }

                Set-TargetResource @testMachineCatalogAbsent;

                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Does not call "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is not assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = ''; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }

                Set-TargetResource @testMachineCatalogAbsent;

                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Does not call "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is assigned to another catalog' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = "$($testMachineCatalogName)2"; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }

                Set-TargetResource @testMachineCatalogAbsent;

                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                Set-TargetResource @testMachineCatalog;

                Assert-MockCalled InvokeScriptBlock -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                $testMachineCatalogWithCredential = $testMachineCatalog.Clone();
                $testMachineCatalogWithCredential['Credential'] = $testCredential;
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }

                Set-TargetResource @testMachineCatalogWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" snapin is registered' {
                Mock -CommandName AssertXDModule -MockWith { };

                Set-TargetResource @testMachineCatalog;

                Assert-MockCalled AssertXDModule -Scope It;
            }
        }

    } #end describe
} #end inmodulescope
