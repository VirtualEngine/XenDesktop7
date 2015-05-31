$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'XD7DesktopGroup' {

    function Get-BrokerDesktopGroup { }
    function New-BrokerDesktopGroup { }
    function Set-BrokerDesktopGroup { }
    function Remove-BrokerDesktopGroup { }
    
    Describe 'XD7DesktopGroup' {

        $testDesktopGroupName = 'TestGroup';
        $testDesktopGroup = @{
            Name = $testDesktopGroupName;
            IsMultiSession = $true;
            DeliveryType = 'AppsOnly';
            DesktopType = 'Shared';
        };
        $testBrokerGroup = @{
            Name = $testDesktopGroupName;
            IsMultiSession = $true;
            DeliveryType = 'AppsOnly';
            Description = $testDesktopGroupName;
            DisplayName = $testDesktopGroupName;
            DesktopType = 'Shared';
            Enabled = $true;
            ColorDepth = 'TwentyFourBit';
            IsMaintenanceMode = $false;
            IsRemotePC = $false;
            IsSecureICA = $false;
            ShutdownDesktopsAfterUse = $false;
            TurnOnAddedMachine = $false;
            Ensure = 'Present';
            SessionSupport = 'MultiSession'; # required to test Set-TargetResource
            DesktopKind = 'Shared'; # required to test Set-TargetResource
        };
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerDesktopGroup { return $testBrokerGroup; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                (Get-TargetResource @testDesktopGroup) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testDesktopGroup;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDesktopGroupWithCredentials = $testDesktopGroup.Clone();
                $testDesktopGroupWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testDesktopGroupWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testDesktopGroup } | Should Throw;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            
            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                (Test-TargetResource @testDesktopGroup) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when all properties match' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                $targetResource = Test-TargetResource @testDesktopGroup;
                $targetResource | Should Be $true;
            }

            It 'Returns False when "Ensure" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -Ensure Absent | Should Be $false;
            }

            It 'Returns False when "IsMultiSession" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                $targetResource = $testDesktopGroup.Clone();
                $targetResource['IsMultiSession'] = $false;
                Test-TargetResource @targetResource | Should Be $false;
            }

            It 'Returns False when "DeliveryType" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                $targetResource = $testDesktopGroup.Clone();
                $targetResource['DeliveryType'] = 'DesktopsOnly';
                Test-TargetResource @targetResource | Should Be $false;
            }

            It 'Returns False when "DesktopType" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                $targetResource = $testDesktopGroup.Clone();
                $targetResource['DesktopType'] = 'Private';
                Test-TargetResource @targetResource | Should Be $false;
            }

            It 'Returns False when "Description" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -Description 'This should not match' | Should Be $false;
            }
            
            It 'Returns False when "DisplayName" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -DisplayName 'This should not match' | Should Be $false;
            }
            
            It 'Returns False when "Enabled" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -Enabled $false | Should Be $false;
            }

            It 'Returns False when "ColorDepth" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -ColorDepth 'EightBit' | Should Be $false;
            }

            It 'Returns False when "IsMaintenanceMode" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -IsMaintenanceMode $true | Should Be $false;
            }

            It 'Returns False when "IsRemotePC" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -IsRemotePC $true | Should Be $false;
            }

            It 'Returns False when "IsSecureIca" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -IsSecureIca $true | Should Be $false;
            }

            It 'Returns False when "ShutdownDesktopsAfterUse" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -ShutdownDesktopsAfterUse $true | Should Be $false;
            }

            It 'Returns False when "TurnOnAddedMachine" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDesktopGroup -TurnOnAddedMachine $true | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Import-Module -MockWith { }
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Calls "New-BrokerDesktopGroup" when "Ensure" = "Present" and delivery group does not exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { }
                Mock -CommandName New-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroup;
                Assert-MockCalled -CommandName New-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Calls "Set-BrokerDesktopGroup" when "Ensure" = "Present" and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Set-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroup;
                Assert-MockCalled -CommandName Set-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Does not call "Remove-BrokerDesktopGroup" when "Ensure" = "Absent" and delivery group does not exist' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Remove-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroup -Ensure Absent;
                Assert-MockCalled -CommandName Remove-BrokerDesktopGroup -Exactly 0 -Scope It;
            }

            It 'Calls "Remove-BrokerDesktopGroup" when "Ensure" = "Absent" and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Remove-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDesktopGroup -Ensure Absent;
                Assert-MockCalled -CommandName Remove-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Throws when changing "IsMultiSession" property and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                $testDesktopGroupMultiSession = $testDesktopGroup.Clone();
                $testDesktopGroupMultiSession['IsMultiSession'] = $false;
                { Set-TargetResource @testDesktopGroupMultiSession }  | Should Throw;
            }

            It 'Throws when changing "DesktopType" property and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                $testDesktopGroupDesktopType = $testDesktopGroup.Clone();
                $testDesktopGroupDesktopType['DesktopType'] = 'Private';
                { Set-TargetResource @testDesktopGroupDesktopType }  | Should Throw;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Set-TargetResource @testDesktopGroup;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDesktopGroupWithCredentials = $testDesktopGroup.Clone();
                $testDesktopGroupWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testDesktopGroupWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Set-TargetResource @testDesktopGroup } | Should Throw;
            }

        } #end context Set-TargetResource

    } #end describe XD7DesktopGroup
} #end inmodulescope
