[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-XDSite { }

    Describe 'XenDesktop7\VE_XD7Site' {

        $testSite = @{
            SiteName = 'Test Site';
            DatabaseServer = 'TestDBServer';
            SiteDatabaseName = 'SiteDB';
            LoggingDatabaseName = 'LoggingDB';
            MonitorDatabaseName = 'MonitorDB';
        };
        $stubSite = [PSCustomObject] @{
            Name = 'Test Site';
            Database = @(
                [PSCustomObject] @{ ServerAddress = 'TestDBServer'; Datastore = 'Site'; Name = 'SiteDB'; }
                [PSCustomObject] @{ ServerAddress = 'TestDBServer'; Datastore = 'Logging'; Name = 'LoggingDB'; }
                [PSCustomObject] @{ ServerAddress = 'TestDBServer'; Datastore = 'Monitor'; Name = 'MonitorDB'; }
            );
        };
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };
            Mock -CommandName Import-Module { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-XDSite -MockWith { return $stubSite; }

                $targetResource = Get-TargetResource @testSite;
                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                $targetResource = Get-TargetResource @testSite;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testSiteWithCredential = $testSite.Clone();
                $testSiteWithCredential['Credential'] = $testCredential;

                $targetResource = Get-TargetResource @testSiteWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.XenDesktop.Admin" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -MockWith { }

                $targetResource = Get-TargetResource @testSite;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName Get-TargetResource -MockWith { return $testSite; }

            It 'Returns True when all properties match' {
                Test-TargetResource @testSite | Should Be $true;
            }

            It 'Returns False when "SiteName" is incorrect' {
                $testSiteCustom = $testSite.Clone();
                $testSiteCustom['SiteName'] = 'Custom';

                Test-TargetResource @testSiteCustom | Should Be $false;
            }

            <# Does not currently check on DatabaseServer - how would we migrate?!
            It 'Returns False when "DatabaseServer" is incorrect' {
                $testSiteCustom = $testSite.Clone();
                $testSiteCustom['DatabaseServer'] = 'Custom';
                Test-TargetResource @testSiteCustom | Should Be $false;
            }
            #>

            It 'Returns False when "SiteDatabaseName" is incorrect' {
                $testSiteCustom = $testSite.Clone();
                $testSiteCustom['SiteDatabaseName'] = 'Custom';

                Test-TargetResource @testSiteCustom | Should Be $false;
            }

            It 'Returns False when "LoggingDatabaseName" is incorrect' {
                $testSiteCustom = $testSite.Clone();
                $testSiteCustom['LoggingDatabaseName'] = 'Custom';

                Test-TargetResource @testSiteCustom | Should Be $false;
            }

            It 'Returns False when "MonitorDatabaseName" is incorrect' {
                $testSiteCustom = $testSite.Clone();
                $testSiteCustom['MonitorDatabaseName'] = 'Custom';

                Test-TargetResource @testSiteCustom | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };
            Mock -CommandName Import-Module { };


            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                Set-TargetResource @testSite;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testSiteWithCredential = $testSite.Clone();
                $testSiteWithCredential['Credential'] = $testCredential;

                Set-TargetResource @testSiteWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.XenDesktop.Admin" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -MockWith { }

                Set-TargetResource @testSite;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -Scope It;
            }

        } #end Set-TargetResource

    } #end describe XD7Site
} #end inmodulescope
