$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'XD7Catalog' {

    function Get-BrokerCatalog { }

    Describe 'XD7Catalog' {

        $testCatalog = @{
            Name = 'Test Catalog';
            Allocation = 'Permanent'; # Permanent, Random, Static
            Provisioning = 'MCS'; # Manual, PVS, MCS
            Persistence = 'PVD'; # Discard, Local, PVD
        }

        $stubCatalog = [PSCustomObject] @{
            Name = 'Test Catalog';
            AllocationType = 'Permanent'; # Permanent, Random, Static
            ProvisioningType = 'MCS'; # Manual, PVS, MCS
            PersistUserChanges = 'OnPvd'; # Discard, OnLocal, OnPvd
            SessionSupport = 'SingleSession'; # SingleSession, MultiSession
            Description = 'This is a test machine catalog';
            PvsAddress = $null;
            PvsDomain = $null;
        };
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Add-PSSnapin -MockWith { }

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerCatalog -MockWith { return $stubCatalog; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                (Get-TargetResource @testCatalog) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Does not throw when machine catalog does not exist' {
                Mock -CommandName Get-BrokerCatalog -ParameterFilter { $Name -eq 'Nonexistent Catalog' -and $ErrorAction -eq 'SilentlyContinue' } -MockWith { Write-Error 'Nonexistent' }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                $nonexistentTestCatalog = $testCatalog.Clone();
                $nonexistentTestCatalog['Name'] = 'Nonexistent Catalog';
                { Get-TargetResource @nonexistentTestCatalog } | Should Not Throw;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testCatalog;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testCatalogWithCredentials = $testCatalog.Clone();
                $testCatalogWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testCatalogWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testCatalog } | Should Throw;
            }

        } #end context Get-TargetResource

    } #end describe XD7Catalog

} #end inmodulescope