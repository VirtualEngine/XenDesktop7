[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function New-XDDatabase { }

    Describe 'XenDesktop7\VE_XD7Database' {

        $testSiteDatabase = @{ SiteName = 'TestSite'; DataStore = 'Site'; DatabaseServer = 'TestServer'; DatabaseName = 'Site'; }
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'TestMSSQLDatabase' {
            $testDatabase = @{ DatabaseServer = 'TestServer'; DatabaseName = 'Site'; }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName InvokeScriptBlock -MockWith { };

                TestMSSQLDatabase @testDatabase;

                Assert-MockCalled InvokeScriptBlock -Exactly 1 -Scope It;
            }
            It 'Invokes script block with credentials and CredSSP when specified' {
                $testDatabaseWithCredential = $testDatabase.Clone();
                $testDatabaseWithCredential['Credential'] = $testCredential;
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }

                TestMSSQLDatabase @testDatabaseWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

        } #end context TestMSSQLDatabase

        Context 'Get-TargetResource' {
            Mock -CommandName TestMSSQLDatabase -MockWith { return $DatabaseNane; }

            It 'Returns a System.Collections.Hashtable type' {
                (Get-TargetResource @testSiteDatabase) -is [System.Collections.Hashtable] | Should Be $true;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName Get-TargetResource -MockWith { return $testSiteDatabase; }

            It 'Returns a System.Boolean type' {
                (Test-TargetResource @testSiteDatabase) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when database exists' {
                Test-TargetResource @testSiteDatabase | Should Be $true;
            }

            It 'Returns False when database does not exist' {
                Mock -CommandName Get-TargetResource -MockWith { return ''; }

                Test-TargetResource @testSiteDatabase | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName AssertXDModule { };
            Mock -CommandName Get-TargetResource -MockWith { return $testSiteDatabase; }
            Mock -CommandName Import-Module { };
            Mock -CommandName InvokeScriptBlock -MockWith { & $ScriptBlock; };

            It 'Calls New-XDDatabase' {
                Mock -CommandName New-XDDatabase { };

                Set-TargetResource @testSiteDatabase;

                Assert-MockCalled -CommandName New-XDDatabase -Exactly 1 -Scope It;
            }

            It 'Invokes script block without credentials by default' {

                Set-TargetResource @testSiteDatabase;

                Assert-MockCalled InvokeScriptBlock -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                $testSiteDatabaseWithCredential = $testSiteDatabase.Clone();
                $testSiteDatabaseWithCredential['Credential'] = $testCredential;
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }

                Set-TargetResource @testSiteDatabaseWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.XenDesktop.Admin" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -MockWith { }

                Set-TargetResource @testSiteDatabase;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -Scope It;
            }

        } #end context Set-TargetResource

    } #end describe XD7Database
} #end inmodulescope
