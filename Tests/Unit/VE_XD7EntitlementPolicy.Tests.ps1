[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerDesktopGroup { }
    function Get-BrokerEntitlementPolicyRule { }
    function Get-BrokerAppEntitlementPolicyRule { }
    function Get-BrokerUser { }
    function New-BrokerUser { }
    function Set-BrokerEntitlementPolicyRule { }
    function Set-BrokerAppEntitlementPolicyRule { }
    function New-BrokerEntitlementPolicyRule { }
    function New-BrokerAppEntitlementPolicyRule { }
    function Remove-BrokerEntitlementPolicyRule { }
    function Remove-BrokerAppEntitlementPolicyRule { }

    Describe 'XenDesktop7\VE_XD7EntitlementPolicy' {

        $testDeliveryGroupName = 'Test Delivery Group';
        $testEntitlementPolicy = @{
            DeliveryGroup = $testDeliveryGroupName;
            EntitlementType = 'Desktop';
        }
        $stubBrokerEntitlementPolicy = @{
            Enabled = $true;
            Description = $null;
            IncludedUsers = @( @{ Name = 'TEST\IncludedUser'; });
            ExcludedUsers = @( @{ Name = 'TEST\ExcludedUser'; });
        }
        $fakeResource = @{
            DeliveryGroup = $testEntitlementPolicy.DeliveryGroup;
            Name = '{0}_{1}' -f $testEntitlementPolicy.DeliveryGroup, $testEntitlementPolicy.EntitlementType;
            EntitlementType = $testEntitlementPolicy.EntitlementType;
            Enabled = $true;
            Description = 'Test Entitlement'; # Description gets coerced into a [System.String]
            IncludeUsers = @('TEST\IncludedUser');
            ExcludeUsers = @('TEST\ExcludedUser');
            Ensure = 'Present';
        }

        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { }
            Mock -CommandName Add-PSSnapin { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerDesktopGroup { return $stubBrokerEntitlementPolicy; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                (Get-TargetResource @testEntitlementPolicy) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Calls "Get-BrokerEntitlementPolicyRule" when "EntitlementType" = "Desktop"' {
                Mock -CommandName Get-BrokerDesktopGroup { return $stubBrokerEntitlementPolicy; }
                Mock -CommandName Get-BrokerEntitlementPolicyRule -MockWith { }
                Mock -CommandName Get-BrokerAppEntitlementPolicyRule -MockWith { }

                $targetResource = Get-TargetResource @testEntitlementPolicy;

                Assert-MockCalled -CommandName Get-BrokerEntitlementPolicyRule -Exactly 1 -Scope It;
                Assert-MockCalled -CommandName Get-BrokerAppEntitlementPolicyRule -Exactly 0 -Scope It;
            }

            It 'Calls "Get-BrokerAppEntitlementPolicyRule" when "EntitlementType" = "Application"' {
                Mock -CommandName Get-BrokerDesktopGroup { return $stubBrokerEntitlementPolicy; }
                Mock -CommandName Get-BrokerEntitlementPolicyRule -MockWith { }
                Mock -CommandName Get-BrokerAppEntitlementPolicyRule -MockWith { }

                $getTargetResourceParams = $testEntitlementPolicy.Clone();
                $getTargetResourceParams['EntitlementType'] = 'Application';

                $targetResource = Get-TargetResource @getTargetResourceParams;

                Assert-MockCalled -CommandName Get-BrokerEntitlementPolicyRule -Exactly 0 -Scope It;
                Assert-MockCalled -CommandName Get-BrokerAppEntitlementPolicyRule -Exactly 1 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                $targetResource = Get-TargetResource @testEntitlementPolicy;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testEntitlementPolicyWithCredential = $testEntitlementPolicy.Clone();
                $testEntitlementPolicyWithCredential['Credential'] = $testCredential;

                $targetResource = Get-TargetResource @testEntitlementPolicyWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -MockWith { }

                Set-TargetResource @testEntitlementPolicy;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            Mock -CommandName AssertXDModule -MockWith { };

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }

                $result = Test-TargetResource @testEntitlementPolicy;

                $result -is [System.Boolean] | Should Be $true;
            }

            It "Passes when entitlement mandatory parameters are correct" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }

                $result = Test-TargetResource @testEntitlementPolicy;

                $result | Should Be $true;
            }

            $testPresentProperties = @(
                'Enabled',
                'Description',
                'IncludeUsers',
                'ExcludeUsers',
                'Ensure'
            )
            foreach ($property in $testPresentProperties) {

                It "Passes when entitlement '$property' is correct" {
                    Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                    $testTargetResourceParams = $testEntitlementPolicy.Clone();
                    $testTargetResourceParams[$property] = $fakeResource[$property];

                    $result = Test-TargetResource @testTargetResourceParams;

                    $result | Should Be $true;
                }
            }

            $testAbsentProperties = @(
                'Enabled',
                'Description',
                'IncludeUsers',
                'ExcludeUsers'
            )
            foreach ($property in $testAbsentProperties) {

                It "Fails when entitlement '$property' is incorrect" {
                    Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                    $testTargetResourceParams = $testEntitlementPolicy.Clone();

                    if ($fakeResource[$property] -is [System.Object[]]) {
                        $testTargetResourceParams[$property] = @('Random','Things');
                    }
                    elseif ($fakeResource[$property] -is [System.String]) {
                        $testTargetResourceParams[$property] = '!{0}' -f $fakeResource[$property];

                    }
                    elseif ($fakeResource[$property] -is [System.Boolean]) {
                        $testTargetResourceParams[$property] = -not $fakeResource[$property];
                    }

                    $result = Test-TargetResource @testTargetResourceParams;

                    $result | Should Be $false;
                }
            }

             #region ValidateSet parameters
            It "Fails when entitlement 'EntitlementType' parameter is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $testTargetResourceParams = $testEntitlementPolicy.Clone();
                $testTargetResourceParams['EntitlementType'] = 'Application';

                $result = Test-TargetResource @testTargetResourceParams;

                $result | Should Be $false;
            }

            It "Fails when entitlement 'Ensure' parameter is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $testTargetResourceParams = $testEntitlementPolicy.Clone();
                $testTargetResourceParams['Ensure'] = 'Absent';

                $result = Test-TargetResource @testTargetResourceParams;

                $result | Should Be $false;
            }
            #endregion ValidateSet parameters

        } #end context Test-TargetResource

    } #end describe XD7EntitlementPolicy

} #end inmodulescope
