$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
Import-Module (Join-Path $here -ChildPath "$sut.psm1") -Force;

InModuleScope 'VE_XD7Administrator' {
    
    function Get-AdminAdministrator { }
    function New-AdminAdministrator { }
    function Set-AdminAdministrator { }
    function Remove-AdminAdministrator { }

    Describe 'VE_XD7Administrator' {

        $testAdmin = @{ Name = 'Test Administrator'; Ensure = 'Present'; Enabled = $true; }
        $testAdminDisabled = @{ Name = 'Test Administrator'; Ensure = 'Present'; Enabled = $false; }
        $testAdminAbsent = @{ Name = 'Test Administrator'; Ensure = 'Absent'; Enabled = $true; }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Add-PSSnapin -MockWith { }
            
            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-AdminAdministrator { return $PSBoundParameters; }
                (Get-TargetResource @testAdmin) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Defaults to "Ensure" = "Present"' {
                #[ref] $null = $testAdminWithNoEnsure.Remove('Ensure');
                (Get-TargetResource @testAdmin).Ensure | Should Be 'Present';
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testAdmin;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testAdminWithCredentials = $testAdmin.Clone();
                $testAdminWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testAdminWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Throws when Citrix.DelegatedAdmin.Admin.V1 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testAdmin } | Should Throw;
            }
            
        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName Get-TargetResource -MockWith { return $testAdmin; }
            
            It 'Returns a System.Boolean type' {
                (Test-TargetResource @testAdmin) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when all properties are correct' {
                Test-TargetResource @testAdmin | Should Be $true;
            }

            It 'Returns True when "Enabled" property is incorrect, but "Ensure" = "Absent"' {
                Mock -CommandName Get-TargetResource -MockWith { return $testAdminAbsent; }
                Test-TargetResource @testAdminAbsent | Should Be $true;
            }

            It 'Returns False when "Enabled" property is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testAdminDisabled; }
                Test-TargetResource @testAdmin | Should Be $false;
            }

            It 'Returns False when "Ensure" property is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testAdminAbsent; }
                Test-TargetResource @testAdmin | Should Be $false;
            }
            
        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Add-PSSnapin -MockWith { }

            It 'Calls New-AdminAdministrator when administrator does not exist' {
                Mock -CommandName Get-AdminAdministrator -MockWith { }
                Mock -CommandName New-AdminAdministrator -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Set-TargetResource @testAdmin;
                Assert-MockCalled -CommandName New-AdminAdministrator -Exactly 1 -Scope It;
            }

            It 'Calls Set-AdminAdministrator when administrator does exist' {
                Mock -CommandName Get-AdminAdministrator -MockWith { return $PSBoundParameters; }
                Mock -CommandName Set-AdminAdministrator -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Set-TargetResource @testAdmin;
                Assert-MockCalled -CommandName Set-AdminAdministrator -Exactly 1 -Scope It;
            }

            It 'Calls Remove-AdminAdministrator when "Ensure" = "Absent"' {
                Mock -CommandName Get-AdminAdministrator -MockWith { return $PSBoundParameters; }
                Mock -CommandName Remove-AdminAdministrator -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Set-TargetResource @testAdminAbsent;
                Assert-MockCalled -CommandName Remove-AdminAdministrator -Exactly 1 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Set-TargetResource @testAdmin;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testAdminWithCredentials = $testAdmin.Clone();
                $testAdminWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testAdminWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Throws when Citrix.DelegatedAdmin.Admin.V1 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testAdmin } | Should Throw;
            }
        } #end context Set-TargetResource
    
    } #end describe XD7Administrator
} #end inmodulescope
