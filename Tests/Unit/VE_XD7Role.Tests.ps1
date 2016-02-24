$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-AdminAdministrator { }
    function Add-AdminRight { }
    function Remove-AdminRight { }

    Describe 'XenDesktop7\VE_XD7Role' {

        $testRoleName = 'Test Role';
        $testRoleNameCustom = 'Custom Role';
        $testScopeName = 'All';
        $testScopeNameCustom = 'Custom Scope';
        $testRoleMembers = @('TEST\USER1','TEST\USER 2');

        $testRole = @{ Name = $testRoleName; Members = $testRoleMembers; };
        $testRoleCustomRole = @{ Name = $testRoleNameCustom; Members = $testRoleMembers; };
        $testScopeCustom = @{ Name = $testRoleName; Members = $testRoleMembers; RoleScope = $roleScopeNameCustom };
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        $stubAdmins = @(
            [PSCustomObject] @{ Name = 'TEST\USER 2'; Enabled = $true; Rights = @( [PSCustomObject] @{ RoleName = $testRoleName; ScopeName = $testScopeName; }; ); }
            [PSCustomObject] @{ Name = 'TEST\USER1'; Enabled = $true; Rights = @( [PSCustomObject] @{ RoleName =  $testRoleName; ScopeName = $testScopeNameCustom; }; ); }
            [PSCustomObject] @{ Name = 'TEST\User Group'; Enabled = $true; Rights = @( [PSCustomObject] @{ RoleName = $testRoleNameCustom; ScopeName = $testScopeName; }; ); }
            [PSCustomObject] @{ Name = 'TEST\User Group 2'; Enabled = $true; Rights = @( [PSCustomObject] @{ RoleName = $testRoleName; ScopeName = $testScopeName; }; ); }
        );
        <# $xdAdminRoleMembers = Get-AdminAdministrator |
                Select-Object -Property Name -ExpandProperty Rights |
                    Where-Object { $_.RoleName -eq $using:Name -and $_.ScopeName -eq $using:RoleScope } |
                        ForEach { $_.Name }; #>

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { }
            Mock -CommandName Add-PSSnapin -MockWith { }

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-AdminAdministrator { return $stubAdmins; }
                $targetResource = Get-TargetResource @testRole;
                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            <#
                Can't appear to mock the Get-AdminAdministrator | Select-Object -Property Name ...
                    The property cannot be processed because the property "Name" already exists.
                    at line: 4 in [nothing here?]

            It 'Returns two "Test Role" administrators' {
                Mock -CommandName Get-AdminAdministrator { return $stubAdmins; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                (Get-TargetResource @testRole).Count | Should Be 2;
            }

            It 'Returns two "All Scope" administrators' {
                Mock -CommandName Get-AdminAdministrator { return $stubAdmins; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                (Get-TargetResource @testRole).Count | Should Be 2;
            }
            #>

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                $targetResource = Get-TargetResource @testRole;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testRoleWithCredentials = $testRole.Clone();
                $testRoleWithCredentials['Credential'] = $testCredentials;

                $targetResource = Get-TargetResource @testRoleWithCredentials;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.DelegatedAdmin.Admin.V1" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.DelegatedAdmin.Admin.V1' } -MockWith { }

                $targetResource = Get-TargetResource @testRole;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.DelegatedAdmin.Admin.V1' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName Get-TargetResource -MockWith { return $testRole; }
            Mock -CommandName Add-PSSnapin -MockWith { }

            It 'Returns a System.Boolean type' {
                (Test-TargetResource @testRole) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Present" and all members are present (by Domain\User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @('TEST\USER1','TEST\group 2','test\user2'); Ensure = 'Present'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('TEST\user1','test\USER2','test\group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Present | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and no members are present (by Domain\User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @(); Ensure = 'Absent'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('TEST\user1','test\USER2','test\group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Absent | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Present" and not all members are present (by Domain\User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @('TEST\group 2'); Ensure = 'Present'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('TEST\user1','test\USER2','test\group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Present | Should Be $false;
            }

            It 'Returns True when "Ensure" = "Present" and all members are present (by User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @('TEST\USER1','TEST\group 2','test\user2'); Ensure = 'Present'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('user1','USER2','group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Present -WarningAction SilentlyContinue | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and no members are present (by User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @(); Ensure = 'Absent'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('user1','USER2','group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Absent | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Present" and not all members are present (by User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @('TEST\group 2'); Ensure = 'Present'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('user1','USER2','group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Present -WarningAction SilentlyContinue | Should Be $false;
            }

            It 'Returns True when "Ensure" = "Absent" and all members are absent (by Domain\User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @('TEST\USER4','TEST\group 5','test\user6'); Ensure = 'Absent'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('TEST\user1','test\USER2','test\group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Absent | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and no members are present (by Domain\User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @(); Ensure = 'Absent'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('TEST\user1','test\USER2','test\group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Absent | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Absent" and not all members are Absent (by Domain\User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @('TEST\group 2'); Ensure = 'Absent'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('TEST\user1','test\USER2','test\group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Absent | Should Be $false;
            }

            It 'Returns True when "Ensure" = "Absent" and all members are absent (by User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @('TEST\USER4','TEST\group 5','test\user6'); Ensure = 'Absent'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('user1','USER2','group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Absent -WarningAction SilentlyContinue | Should Be $true;
            }

            It 'Returns True when "Ensure" = "Absent" and no members are present (by User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @(); Ensure = 'Absent'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('user1','USER2','group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Absent | Should Be $true;
            }

            It 'Returns False when "Ensure" = "Absent" and not all members are Absent (by User)' {
                $getTargetResource = @{ Name = 'Test Role'; Members = @('TEST\group 2'); Ensure = 'Absent'; };
                $testTargetResource = @{ Name = 'Test Role'; Members = @('user1','USER2','group 2'); };
                Mock -CommandName Get-TargetResource -MockWith { return $getTargetResource; }

                Test-TargetResource @testTargetResource -Ensure Absent -WarningAction SilentlyContinue | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { }
            Mock -CommandName Add-PSSnapin -MockWith { }

            It 'Calls "Add-AdminRight" once per administrator when "Ensure" = "Present"' {
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Mock -CommandName Add-AdminRight -MockWith { }

                Set-TargetResource @testRole;

                Assert-MockCalled -CommandName Add-AdminRight -Exactly $testRole.Members.Count -Scope It;
            }

            It 'Calls "Remove-AdminRight" once per administrator when "Ensure" = "Absent"' {
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Mock -CommandName Get-AdminAdministrator -MockWith { return [PSCustomObject] @{ Rights = @{ RoleName = $testRoleName; ScopeName = $testScopeName; } } }
                Mock -CommandName Remove-AdminRight -MockWith { }

                Set-TargetResource @testRole -Ensure Absent;

                Assert-MockCalled -CommandName Remove-AdminRight -Exactly $testRole.Members.Count -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                Set-TargetResource @testRole;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testRoleWithCredentials = $testRole.Clone();
                $testRoleWithCredentials['Credential'] = $testCredentials;

                Set-TargetResource @testRoleWithCredentials;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.DelegatedAdmin.Admin.V1" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.DelegatedAdmin.Admin.V1' } -MockWith { }

                Set-TargetResource @testRole;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.DelegatedAdmin.Admin.V1' } -Scope It;
            }

        } #end context Set-TargetResource

    } #end descrivbe XD7Role
} #end inmodulescope
