$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'XD7MachineCatalogMachine' {

    function Get-BrokerCatalog { }
    function Get-BrokerMachine { }
    function New-BrokerMachine { }
    function Remove-BrokerMachine { }

    Describe 'XD7MachineCatalogMachine' {

        $testMachineCatalogName = 'TestGroup';
        $testMachineCatalogMembers = @('TestMachine.local');
        $testMachineCatalog = @{ Name = $testMachineCatalogName; Members = $testMachineCatalogMembers; Ensure = 'Present'; }
        $testMachineCatalogAbsent = @{ Name = $testMachineCatalogName; Members = $testMachineCatalogMembers; Ensure = 'Absent'; }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerMachine { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                (Get-TargetResource @testMachineCatalog) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testMachineCatalog;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testMachineCatalogWithCredentials = $testMachineCatalog.Clone();
                $testMachineCatalogWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testMachineCatalogWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testMachineCatalog } | Should Throw;
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
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Import-Module -MockWith { }
            Mock -CommandName Add-PSSnapin -MockWith { };
            Mock -CommandName Get-BrokerCatalog -MockWith { return @{ Name = $testCatalogName; Uid = 1; }; }

            It 'Calls "New-BrokerMachine" when "Ensure" = "Present" and machine is registered, but not assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = $null }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName New-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testMachineCatalog;
                Assert-MockCalled -CommandName New-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Does not call "New-BrokerMachine" when "Ensure" = "Present" and machine is registered and assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = $testMachineCatalogName; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName New-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testMachineCatalog;
                Assert-MockCalled -CommandName New-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Throws when "Ensure" = "Present" and machine is not registered' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return $null; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $null; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                { Set-TargetResource @testMachineCatalog } | Should Throw;
            }

            It 'Calls "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is registered and assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = $testMachineCatalogName; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testMachineCatalogAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Does not call "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is not assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = ''; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testMachineCatalogAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Does not call "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is assigned to another catalog' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testMachineCatalog; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ CatalogName = "$($testMachineCatalogName)2"; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testMachineCatalogMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testMachineCatalogAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Set-TargetResource @testMachineCatalog;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testMachineCatalogWithCredentials = $testMachineCatalog.Clone();
                $testMachineCatalogWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testMachineCatalogWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Set-TargetResource @testMachineCatalog } | Should Throw;
            }
        }

    } #end describe
} #end inmodulescope
