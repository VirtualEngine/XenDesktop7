$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function New-XDDatabase { }
    
    Describe 'XenDesktop7\VE_XD7Database' {

        $testSiteDatabase = @{ SiteName = 'TestSite'; DataStore = 'Site'; DatabaseServer = 'TestServer'; DatabaseName = 'Site'; }
        $testLoggingDatabase = @{ SiteName = 'TestSite'; DataStore = 'Logging'; DatabaseServer = 'TestServer'; DatabaseName = 'Logging'; }
        $testMonitorDatabase = @{ SiteName = 'TestSite'; DataStore = 'Monitor'; DatabaseServer = 'TestServer'; DatabaseName = 'Monitor'; }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'TestMSSQLDatabase' {
            $testDatabase = @{ DatabaseServer = 'TestServer'; DatabaseName = 'Site'; }
            
            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                TestMSSQLDatabase @testDatabase;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }
            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDatabaseWithCredentials = $testDatabase.Clone();
                $testDatabaseWithCredentials['Credential'] = $testCredentials;
                TestMSSQLDatabase @testDatabaseWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
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
            Mock -CommandName Get-TargetResource -MockWith { return $testSiteDatabase; }
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Import-Module { };

            It 'Calls New-XDDatabase' {
                Mock -CommandName New-XDDatabase { };
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Set-TargetResource @testSiteDatabase;
                Assert-MockCalled -CommandName New-XDDatabase -Exactly 1 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Set-TargetResource @testSiteDatabase;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testSiteDatabaseWithCredentials = $testSiteDatabase.Clone();
                $testSiteDatabaseWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testSiteDatabaseWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Throws when Citrix.XenDesktop.Admin is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Set-TargetResource @testSiteDatabase } | Should Throw;
            }

        } #end context Set-TargetResource
    
    } #end describe XD7Database
} #end inmodulescope
