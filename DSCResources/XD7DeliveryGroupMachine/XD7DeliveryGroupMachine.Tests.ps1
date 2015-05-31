$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'XD7DeliveryGroupMachine' {

    function Get-BrokerMachine { }
    function Remove-BrokerMachine { }
    function Add-BrokerMachine { }
    
    Describe 'XD7DeliveryGroupMachine' {
        
        $testDeliveryGroupName = 'TestGroup';
        $testDeliveryGroupMembers = @('TestMachine.local');
        $testDeliveryGroupMachine = @{ Name = $testDeliveryGroupName; Members = $testDeliveryGroupMembers; Ensure = 'Present'; }
        $testDeliveryGroupMachineAbsent = @{ Name = $testDeliveryGroupName; Members = $testDeliveryGroupMembers; Ensure = 'Absent'; }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerMachine { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                (Get-TargetResource @testDeliveryGroupMachine) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testDeliveryGroupMachine;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDeliveryGroupMachineWithCredentials = $testDeliveryGroupMachine.Clone();
                $testDeliveryGroupMachineWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testDeliveryGroupMachineWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testDeliveryGroupMachine } | Should Throw;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName Import-Module -MockWith { }

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $testDeliveryGroupMachine; }
                (Test-TargetResource @testDeliveryGroupMachine -WarningAction SilentlyContinue) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when delivery group membership is correct' {
                Mock -CommandName TestXDMachineMembership -MockWith { return $true; }
                Mock -CommandName Get-TargetResource -MockWith { return $testDeliveryGroupMachine; }
                Test-TargetResource @testDeliveryGroupMachine | Should Be $true;
            }

            It 'Returns False when delivery catalog membership is incorrect' {
                Mock -CommandName TestXDMachineMembership -MockWith { return $false; }
                Mock -CommandName Get-TargetResource -MockWith { return $testDeliveryGroupMachine; }
                Test-TargetResource @testDeliveryGroupMachine | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Import-Module -MockWith { }
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Calls "Add-BrokerMachine" when "Ensure" = "Present" and machine is registered, but not assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDeliveryGroupMachine; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = $null }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDeliveryGroupMembers[0]; }
                Mock -CommandName Add-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroupMachine;
                Assert-MockCalled -CommandName Add-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Calls "Add-BrokerMachine" when "Ensure" = "Present" and machine is registered, but assigned to another group' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDeliveryGroupMachine; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = "$($testDeliveryGroupName)2"; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDeliveryGroupMembers[0]; }
                Mock -CommandName Add-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroupMachine;
                Assert-MockCalled -CommandName Add-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Does not call "Add-BrokerMachine" when "Ensure" = "Present" and machine is registered and assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDeliveryGroupMachine; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = $testDeliveryGroupName; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDeliveryGroupMembers[0]; }
                Mock -CommandName Add-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroupMachine;
                Assert-MockCalled -CommandName Add-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Throws when "Ensure" = "Present" and machine is not registered' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDeliveryGroupMachine; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return $null; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $null; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                { Set-TargetResource @testDeliveryGroupMachine } | Should Throw;
            }

            It 'Calls "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is registered and assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDeliveryGroupMachine; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = $testDeliveryGroupName; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDeliveryGroupMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroupMachineAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 1 -Scope It;
            }

            It 'Does not call "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is not assigned' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDeliveryGroupMachine; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = ''; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDeliveryGroupMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroupMachineAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Does not call "Remove-BrokerMachine" when "Ensure" = "Absent" and machine is assigned to another group' {
                Mock -CommandName Get-BrokerMachine -MockWith { return $testDeliveryGroupMachine; }
                Mock -CommandName ResolveXDBrokerMachine -MockWith { return @{ DesktopGroupName = "$($testDeliveryGroupName)2"; }; }
                Mock -CommandName GetXDBrokerMachine -MockWith { return $testDeliveryGroupMembers[0]; }
                Mock -CommandName Remove-BrokerMachine -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroupMachineAbsent;
                Assert-MockCalled -CommandName Remove-BrokerMachine -Exactly 0 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Set-TargetResource @testDeliveryGroupMachine;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDeliveryGroupMachineWithCredentials = $testDeliveryGroupMachine.Clone();
                $testDeliveryGroupMachineWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testDeliveryGroupMachineWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Set-TargetResource @testDeliveryGroupMachine } | Should Throw;
            }

        } #end context Test-TargetResource

    } #end describe XD7DeliveryGroupMachine
} #end inmodulescope