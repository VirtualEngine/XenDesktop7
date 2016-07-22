$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerCatalog { }

    Describe 'XenDesktop7\VE_XD7Catalog' {

        $testCatalog = @{
            Name = 'Test Catalog';
            Allocation = 'Permanent'; # Permanent, Random, Static
            Provisioning = 'MCS'; # Manual, PVS, MCS
            Persistence = 'PVD'; # Discard, Local, PVD
        }

        $fakeResource = @{
            Name = $testCatalog.Name;
            Allocation = $testCatalog.Allocation;
            Provisioning = $testCatalog.Provisioning;
            Persistence = $testCatalog.Persistence;
            IsMultiSession = $false;
            Description = 'This is a test machine catalog';
            PvsAddress = 'pvs.contoso.com';
            PvsDomain = 'PVSDomain';
            Ensure = 'Present';
        }

        $fakeBrokerCatalog = [PSCustomObject] @{
            Name = $stubCatalog.Name;
            AllocationType = $stubCatalog.Allocation;
            ProvisioningType = $stubCatalog.Provisioning;
            PersistUserChanges = 'OnPvd'; # Discard, OnLocal, OnPvd
            SessionSupport = 'SingleSession'; # SingleSession, MultiSession
            Description = $stubCatalog.Description;
            PvsAddress = $stubCatalog.PvsAddress;
            PvsDomain = $stubCatalog.PvsDomain;
        };
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };
            Mock -CommandName Add-PSSnapin -MockWith { }

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerCatalog -MockWith { return $fakeBrokerCatalog; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                (Get-TargetResource @testCatalog) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Does not throw when machine catalog does not exist' {
                $nonexistentTestCatalog = $testCatalog.Clone();
                $nonexistentTestCatalog['Name'] = 'Nonexistent Catalog';
                Mock -CommandName Get-BrokerCatalog -ParameterFilter { $Name -eq 'Nonexistent Catalog' -and $ErrorAction -eq 'SilentlyContinue' } -MockWith { Write-Error 'Nonexistent' }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                { Get-TargetResource @nonexistentTestCatalog } | Should Not Throw;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                Get-TargetResource @testCatalog;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                $testCatalogWithCredential = $testCatalog.Clone();
                $testCatalogWithCredential['Credential'] = $testCredential;
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }

                Get-TargetResource @testCatalogWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" snapin is registered' {
                Mock -CommandName AssertXDModule -MockWith { };

                Get-TargetResource @testCatalog;

                Assert-MockCalled AssertXDModule -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }

                (Test-TargetResource @testCatalog) -is [System.Boolean] | Should Be $true;
            }

            It "Passes when catalog mandatory parameters are correct" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }

                $result = Test-TargetResource @testCatalog;

                $result | Should Be $true;
            }

            $testPresentProperties = @(
                'IsMultiSession',
                'Description',
                'PvsAddress',
                'PvsDomain',
                'Ensure'
            )
            foreach ($property in $testPresentProperties) {

                It "Passes when catalog '$property' is correct" {
                    Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                    $testTargetResourceParams = $testCatalog.Clone();
                    $testTargetResourceParams[$property] = $fakeResource[$property];

                    $result = Test-TargetResource @testTargetResourceParams;

                    $result | Should Be $true;
                }
            }

            $testAbsentProperties = @(
                'Name',
                'IsMultiSession',
                'Description',
                'PvsAddress',
                'PvsDomain'
            )
            foreach ($property in $testAbsentProperties) {

                It "Fails when catalog '$property' is incorrect" {
                    Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                    $testTargetResourceParams = $testCatalog.Clone();

                    if ($fakeResource[$property] -is [System.String]) {
                        $testTargetResourceParams[$property] = '!{0}' -f $fakeResource[$property];

                    }
                    elseif ($fakeResource[$property] -is [System.Boolean]) {
                        $testTargetResourceParams[$property] = -not $fakeResource[$property];
                    }

                    $result = Test-TargetResource @testTargetResourceParams;

                    $result | Should Be $false;
                }
            }

            It "Fails when catalog 'Allocation' is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $missingCatalog = $fakeResource.Clone();
                $missingCatalog['Allocation'] = 'Static';

                $result = Test-TargetResource @missingCatalog;

                $result | Should Be $false;
            }

            It "Fails when catalog 'Provisioning' is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $missingCatalog = $fakeResource.Clone();
                $missingCatalog['Provisioning'] = 'Manual';

                $result = Test-TargetResource @missingCatalog;

                $result | Should Be $false;
            }

            It "Fails when catalog 'Persistence' is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $missingCatalog = $fakeResource.Clone();
                $missingCatalog['Persistence'] = 'Discard';

                $result = Test-TargetResource @missingCatalog;

                $result | Should Be $false;
            }

            It "Fails when catalog 'Ensure' is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $missingCatalog = $fakeResource.Clone();
                $missingCatalog['Ensure'] = 'Absent';

                $result = Test-TargetResource @missingCatalog;

                $result | Should Be $false;
            }



        } #end context Test-TargetResource

    } #end describe XD7Catalog

} #end inmodulescope
