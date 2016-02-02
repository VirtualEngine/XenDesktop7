$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'VE_XD7DesktopGroupMember' {

    function Get-BrokerMachine { }
    function Remove-BrokerMachine { }
    function Add-BrokerMachine { }
    
    Describe 'VE_XD7DesktopGroupMember' {
        
        $testDesktopGroupName = 'TestGroup';
        $testDesktopGroupMembers = @('TestMachine.local');
        $testDesktopGroupMember = @{ Name = $testDesktopGroupName; Members = $testDesktopGroupMembers; Ensure = 'Present'; }
        $testDesktopGroupMemberAbsent = @{ Name = $testDesktopGroupName; Members = $testDesktopGroupMembers; Ensure = 'Absent'; }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerMachine { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                (Get-TargetResource @testDesktopGroupMember) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testDesktopGroupMember;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDesktopGroupMemberWithCredentials = $testDesktopGroupMember.Clone();
                $testDesktopGroupMemberWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testDesktopGroupMemberWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testDesktopGroupMember } | Should Throw;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName Import-Module -MockWith { }

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $testDesktopGroupMember; }
                (Test-TargetResource @testDesktopGroupMember -WarningAction SilentlyContinue) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when delivery group membership is correct' {
                Mock -CommandName TestXDMachineMembership -MockWith { return $true; }
                Mock -CommandName Get-TargetResource -MockWith { return $testDesktopGroupMember; }
                Test-TargetResource @testDesktopGroupMember | Should Be $true;
            }

            It 'Returns False when delivery catalog membership is incorrect' {
                Mock -CommandName TestXDMachineMembership -MockWith { return $false; }
                Mock -CommandName Get-TargetResource -MockWith { return $testDesktopGroupMember; }
                Test-TargetResource @testDesktopGroupMember | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Import-Module -MockWith { }
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Calls "Add-BrokerMachine" when "Ensure" = "Present" and machine is registered, but not assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDesktopGroupMember; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = $null }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDesktopGroupMembers[0]; }
                Mock -CommandName Add-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroupMember;
                Assert-MockCalled -CommandName Add-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Calls "Add-BrokerMachine" when "Ensure" = "Present" and machine is registered, but assigned to another group' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDesktopGroupMember; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = "$($testDesktopGroupName)2"; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDesktopGroupMembers[0]; }
                Mock -CommandName Add-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroupMember;
                Assert-MockCalled -CommandName Add-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Does not call "Add-BrokerMachine" when "Ensure" = "Present" and machine is registered and assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDesktopGroupMember; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = $testDesktopGroupName; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDesktopGroupMembers[0]; }
                Mock -CommandName Add-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroupMember;
                Assert-MockCalled -CommandName Add-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Throws when "Ensure" = "Present" and machine is not registered' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDesktopGroupMember; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return $null; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $null; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                { Set-TargetResource @testDesktopGroupMember } | Should Throw;
            }

            It 'Calls "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is registered and assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDesktopGroupMember; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = $testDesktopGroupName; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDesktopGroupMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroupMemberAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Does not call "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is not assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDesktopGroupMember; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = ''; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDesktopGroupMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroupMemberAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Does not call "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is assigned to another group' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDesktopGroupMember; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = "$($testDesktopGroupName)2"; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDesktopGroupMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroupMemberAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Set-TargetResource @testDesktopGroupMember;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDesktopGroupMemberWithCredentials = $testDesktopGroupMember.Clone();
                $testDesktopGroupMemberWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testDesktopGroupMemberWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Set-TargetResource @testDesktopGroupMember } | Should Throw;
            }

        } #end context Test-TargetResource

    } #end describe XD7DesktopGroupMember
} #end inmodulescope