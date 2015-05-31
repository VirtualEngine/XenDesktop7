$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'XD7DeliveryGroup' {

    function Get-BrokerDesktopGroup { }
    function New-BrokerDesktopGroup { }
    function Set-BrokerDesktopGroup { }
    function Remove-BrokerDesktopGroup { }
    
    Describe 'XD7DeliveryGroup' {

        $testDeliveryGroupName = 'TestGroup';
        $testDeliveryGroup = @{
            Name = $testDeliveryGroupName;
            IsMultiSession = $true;
            DeliveryType = 'AppsOnly';
            DesktopType = 'Shared';
        };
        $testBrokerGroup = @{
            Name = $testDeliveryGroupName;
            IsMultiSession = $true;
            DeliveryType = 'AppsOnly';
            Description = $testDeliveryGroupName;
            DisplayName = $testDeliveryGroupName;
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
                (Get-TargetResource @testDeliveryGroup) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testDeliveryGroup;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDeliveryGroupWithCredentials = $testDeliveryGroup.Clone();
                $testDeliveryGroupWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testDeliveryGroupWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testDeliveryGroup } | Should Throw;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            
            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                (Test-TargetResource @testDeliveryGroup) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when all properties match' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                $targetResource = Test-TargetResource @testDeliveryGroup;
                $targetResource | Should Be $true;
            }

            It 'Returns False when "Ensure" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -Ensure Absent | Should Be $false;
            }

            It 'Returns False when "IsMultiSession" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                $targetResource = $testDeliveryGroup.Clone();
                $targetResource['IsMultiSession'] = $false;
                Test-TargetResource @targetResource | Should Be $false;
            }

            It 'Returns False when "DeliveryType" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                $targetResource = $testDeliveryGroup.Clone();
                $targetResource['DeliveryType'] = 'DesktopsOnly';
                Test-TargetResource @targetResource | Should Be $false;
            }

            It 'Returns False when "DesktopType" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                $targetResource = $testDeliveryGroup.Clone();
                $targetResource['DesktopType'] = 'Private';
                Test-TargetResource @targetResource | Should Be $false;
            }

            It 'Returns False when "Description" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -Description 'This should not match' | Should Be $false;
            }
            
            It 'Returns False when "DisplayName" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -DisplayName 'This should not match' | Should Be $false;
            }
            
            It 'Returns False when "Enabled" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -Enabled $false | Should Be $false;
            }

            It 'Returns False when "ColorDepth" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -ColorDepth 'EightBit' | Should Be $false;
            }

            It 'Returns False when "IsMaintenanceMode" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -IsMaintenanceMode $true | Should Be $false;
            }

            It 'Returns False when "IsRemotePC" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -IsRemotePC $true | Should Be $false;
            }

            It 'Returns False when "IsSecureIca" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -IsSecureIca $true | Should Be $false;
            }

            It 'Returns False when "ShutdownDesktopsAfterUse" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -ShutdownDesktopsAfterUse $true | Should Be $false;
            }

            It 'Returns False when "TurnOnAddedMachine" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $testBrokerGroup; }
                Test-TargetResource @testDeliveryGroup -TurnOnAddedMachine $true | Should Be $false;
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
                Set-TargetResource @testDeliveryGroup;
                Assert-MockCalled -CommandName New-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Calls "Set-BrokerDesktopGroup" when "Ensure" = "Present" and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Set-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroup;
                Assert-MockCalled -CommandName Set-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Does not call "Remove-BrokerDesktopGroup" when "Ensure" = "Absent" and delivery group does not exist' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Remove-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroup -Ensure Absent;
                Assert-MockCalled -CommandName Remove-BrokerDesktopGroup -Exactly 0 -Scope It;
            }

            It 'Calls "Remove-BrokerDesktopGroup" when "Ensure" = "Absent" and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Remove-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                Set-TargetResource @testDeliveryGroup -Ensure Absent;
                Assert-MockCalled -CommandName Remove-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Throws when changing "IsMultiSession" property and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                $testDeliveryGroupMultiSession = $testDeliveryGroup.Clone();
                $testDeliveryGroupMultiSession['IsMultiSession'] = $false;
                { Set-TargetResource @testDeliveryGroupMultiSession }  | Should Throw;
            }

            It 'Throws when changing "DesktopType" property and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock }
                $testDeliveryGroupDesktopType = $testDeliveryGroup.Clone();
                $testDeliveryGroupDesktopType['DesktopType'] = 'Private';
                { Set-TargetResource @testDeliveryGroupDesktopType }  | Should Throw;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Set-TargetResource @testDeliveryGroup;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testDeliveryGroupWithCredentials = $testDeliveryGroup.Clone();
                $testDeliveryGroupWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testDeliveryGroupWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Set-TargetResource @testDeliveryGroup } | Should Throw;
            }

        } #end context Set-TargetResource

    } #end describe XD7DeliveryGroup
} #end inmodulescope
