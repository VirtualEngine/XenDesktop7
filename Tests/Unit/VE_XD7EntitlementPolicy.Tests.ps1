$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerDesktopGroup { }
    function Get-BrokerEntitlementPolicyRule { }
    function Get-BrokerAppEntitlementPolicyRule { }

    Describe 'XenDesktop7\VE_XD7EntitlementPolicy' {

        $testDeliveryGroupName = 'Test Delivery Group';
        $testEntitlementPolicy = @{
            DeliveryGroup = $testDeliveryGroupName;
        }
        $stubBrokerEntitlementPolicy = @{
            Enabled = $true;
            Description = $null;
            IncludedUsers = @( @{ Name = 'TEST\IncludedUser'; });
            ExcludedUsers = @( @{ Name = 'TEST\ExcludedUser'; });
        }
        $stubDesktopTargetResource = @{
            DeliveryGroup = $testDeliveryGroupName;
            EntitlementType = 'Desktop';
            Enabled = $true;
            Name = "$($testDeliveryGroupName)_Desktop";
            Description = ''; # Description gets coerced into a [System.String]
            IncludeUsers = @('TEST\IncludedUser');
            ExcludeUsers = @('TEST\ExcludedUser');
            Ensure = 'Present';
        }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { }
            Mock -CommandName Add-PSSnapin { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerDesktopGroup { return $stubBrokerEntitlementPolicy; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                (Get-TargetResource @testEntitlementPolicy -EntitlementType Desktop) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Calls "Get-BrokerEntitlementPolicyRule" when "EntitlementType" = "Desktop"' {
                Mock -CommandName Get-BrokerDesktopGroup { return $stubBrokerEntitlementPolicy; }
                Mock -CommandName Get-BrokerEntitlementPolicyRule -MockWith { }
                Mock -CommandName Get-BrokerAppEntitlementPolicyRule -MockWith { }

                $targetResource = Get-TargetResource @testEntitlementPolicy -EntitlementType Desktop;

                Assert-MockCalled -CommandName Get-BrokerEntitlementPolicyRule -Exactly 1 -Scope It;
                Assert-MockCalled -CommandName Get-BrokerAppEntitlementPolicyRule -Exactly 0 -Scope It;
            }

            It 'Calls "Get-BrokerAppEntitlementPolicyRule" when "EntitlementType" = "Application"' {
                Mock -CommandName Get-BrokerDesktopGroup { return $stubBrokerEntitlementPolicy; }
                Mock -CommandName Get-BrokerEntitlementPolicyRule -MockWith { }
                Mock -CommandName Get-BrokerAppEntitlementPolicyRule -MockWith { }

                $targetResource = Get-TargetResource @testEntitlementPolicy -EntitlementType Application;

                Assert-MockCalled -CommandName Get-BrokerEntitlementPolicyRule -Exactly 0 -Scope It;
                Assert-MockCalled -CommandName Get-BrokerAppEntitlementPolicyRule -Exactly 1 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                $targetResource = Get-TargetResource @testEntitlementPolicy -EntitlementType Desktop;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testEntitlementPolicyWithCredentials = $testEntitlementPolicy.Clone();
                $testEntitlementPolicyWithCredentials['Credential'] = $testCredentials;

                $targetResource = Get-TargetResource @testEntitlementPolicyWithCredentials -EntitlementType Desktop;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -MockWith { }

                Set-TargetResource @testEntitlementPolicy -EntitlementType Desktop

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }

                (Test-TargetResource @testEntitlementPolicy -EntitlementType Desktop) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when all properties are equal' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = 'TEST\IncludedUser';
                    ExcludeUsers = 'TEST\ExcludedUser';
                }

                Test-TargetResource @targetResourceParams | Should Be $true;
            }

            It 'Returns False when "Ensure" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = 'TEST\IncludedUser';
                    ExcludeUsers = 'TEST\ExcludedUser';
                    Ensure = 'Absent';
                }

                Test-TargetResource @targetResourceParams | Should Be $false;
            }

            It 'Returns False when "Enabled" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = 'TEST\IncludedUser';
                    ExcludeUsers = 'TEST\ExcludedUser';
                    Enabled = $false;
                }

                Test-TargetResource @targetResourceParams | Should Be $false;
            }

            It 'Returns False when "Name" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = 'TEST\IncludedUser';
                    ExcludeUsers = 'TEST\ExcludedUser';
                    Name = 'My Custom Name';
                }

                Test-TargetResource @targetResourceParams | Should Be $false;
            }

            It 'Returns False when "Description" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = 'TEST\IncludedUser';
                    ExcludeUsers = 'TEST\ExcludedUser';
                    Description = 'My Custom Description';
                }

                Test-TargetResource @targetResourceParams | Should Be $false;
            }

            It 'Returns False when "ExcludeUsers" has additional members' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = 'TEST\IncludedUser';
                    ExcludeUsers = 'TEST\ExcludedUser','TEST\IncludedUser';
                }

                Test-TargetResource @targetResourceParams | Should Be $false;
            }

            It 'Returns False when "ExcludeUsers" has missing members' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = 'TEST\IncludedUser';
                    ExcludeUsers = '';
                }

                Test-TargetResource @targetResourceParams | Should Be $false;
            }

            It 'Returns False when "IncludeUsers" has additional members' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = 'TEST\IncludedUser','TEST\ExcludedUser';
                    ExcludeUsers = 'TEST\ExcludedUser';
                }

                Test-TargetResource @targetResourceParams | Should Be $false;
            }

            It 'Returns False when "IncludeUsers" has missing members' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubDesktopTargetResource; }
                $targetResourceParams = @{
                    DeliveryGroup = $testDeliveryGroupName;
                    EntitlementType = 'Desktop';
                    IncludeUsers = '';
                    ExcludeUsers = 'TEST\ExcludedUser';
                }

                Test-TargetResource @targetResourceParams | Should Be $false;
            }

        } #end context Test-TargetResource

    } #end describe XD7EntitlementPolicy

} #end inmodulescope
