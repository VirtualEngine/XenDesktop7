[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerDesktopGroup { }
    function New-BrokerDesktopGroup { }
    function Set-BrokerDesktopGroup { }
    function Remove-BrokerDesktopGroup { }

    Describe 'XenDesktop7\VE_XD7DesktopGroup' {

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
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule { };
            Mock -CommandName Add-PSSnapin -MockWith { };
            Mock -CommandName InvokeScriptBlock -MockWith { & $ScriptBlock; };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerDesktopGroup { return $testBrokerGroup; }

                (Get-TargetResource @testDesktopGroup) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Get-TargetResource @testDesktopGroup;

                Assert-MockCalled InvokeScriptBlock -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                $testDesktopGroupWithCredential = $testDesktopGroup.Clone();
                $testDesktopGroupWithCredential['Credential'] = $testCredential;
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }

                Get-TargetResource @testDesktopGroupWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -MockWith { }

                Get-TargetResource @testDesktopGroup;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -Scope It;
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
            Mock -CommandName AssertXDModule { };
            Mock -CommandName Import-Module -MockWith { };
            Mock -CommandName Add-PSSnapin -MockWith { };
            Mock -CommandName InvokeScriptBlock -MockWith { & $ScriptBlock; };

            It 'Calls "New-BrokerDesktopGroup" when "Ensure" = "Present" and delivery group does not exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { }
                Mock -CommandName New-BrokerDesktopGroup -MockWith { }

                Set-TargetResource @testDesktopGroup;

                Assert-MockCalled -CommandName New-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Calls "Set-BrokerDesktopGroup" when "Ensure" = "Present" and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Set-BrokerDesktopGroup -MockWith { }

                Set-TargetResource @testDesktopGroup;

                Assert-MockCalled -CommandName Set-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Does not call "Remove-BrokerDesktopGroup" when "Ensure" = "Absent" and delivery group does not exist' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { }
                Mock -CommandName Remove-BrokerDesktopGroup -MockWith { }

                Set-TargetResource @testDesktopGroup -Ensure Absent;

                Assert-MockCalled -CommandName Remove-BrokerDesktopGroup -Exactly 0 -Scope It;
            }

            It 'Calls "Remove-BrokerDesktopGroup" when "Ensure" = "Absent" and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                Mock -CommandName Remove-BrokerDesktopGroup -MockWith { }

                Set-TargetResource @testDesktopGroup -Ensure Absent;

                Assert-MockCalled -CommandName Remove-BrokerDesktopGroup -Exactly 1 -Scope It;
            }

            It 'Throws when changing "IsMultiSession" property and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                $testDesktopGroupMultiSession = $testDesktopGroup.Clone();
                $testDesktopGroupMultiSession['IsMultiSession'] = $false;

                { Set-TargetResource @testDesktopGroupMultiSession }  | Should Throw;
            }

            It 'Throws when changing "DesktopType" property and delivery group exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $testBrokerGroup; }
                $testDesktopGroupDesktopType = $testDesktopGroup.Clone();
                $testDesktopGroupDesktopType['DesktopType'] = 'Private';

                { Set-TargetResource @testDesktopGroupDesktopType }  | Should Throw;
            }

            It 'Invokes script block without credentials by default' {

                Set-TargetResource @testDesktopGroup;

                Assert-MockCalled InvokeScriptBlock -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testDesktopGroupWithCredential = $testDesktopGroup.Clone();
                $testDesktopGroupWithCredential['Credential'] = $testCredential;

                Set-TargetResource @testDesktopGroupWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -MockWith { }

                Set-TargetResource @testDesktopGroup

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -Scope It;
            }

        } #end context Set-TargetResource

    } #end describe XD7DesktopGroup
} #end inmodulescope
