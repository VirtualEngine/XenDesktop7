$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerDesktopGroup { }
    function Get-BrokerAccessPolicyRule { }

    Describe 'XenDesktop7\VE_XD7AccessPolicy' {

        $testDeliveryGroupName = 'Test Access Policy';
        $testAccessPolicy = @{
            DeliveryGroup = $testDeliveryGroupName;
            AccessType = 'AccessGateway';
        }

        $fakeResource = @{
            DeliveryGroup = $testAccessPolicy.DeliveryGroup;
            AccessType = $testAccessPolicy.AccessType;
            Enabled = $true;
            AllowRestart = $true;
            Protocol = @('HDX','RDP');
            Name = 'Test Access Policy';
            Description = 'Test Access Policy';
            IncludeUsers = @();
            ExcludeUsers = @();
            Ensure = 'Present';
        }

        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                (Get-TargetResource @testAccessPolicy) -is [System.Collections.Hashtable] | Should Be $true;
            }

             It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                Get-TargetResource @testAccessPolicy;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testAccessPolicyWithCredential = $testAccessPolicy.Clone();
                $testAccessPolicyWithCredential['Credential'] = $testCredential;

                Get-TargetResource @testAccessPolicyWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" snapin is registered' {
                Mock -CommandName AssertXDModule -MockWith { };

                Get-TargetResource @testAccessPolicy;

                Assert-MockCalled AssertXDModule -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }

                $result = Test-TargetResource @testAccessPolicy;

                $result -is [System.Boolean] | Should Be $true;
            }

            It "Passes when access policy mandatory parameters are correct" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }

                $result = Test-TargetResource @testAccessPolicy;

                $result | Should Be $true;
            }

            $testPresentProperties = @(
                'DeliveryGroup',
                'Enabled',
                'AllowRestart',
                'Name',
                'Description',
                'IncludeUsers',
                'ExcludeUsers',
                'Ensure'
            )
            foreach ($property in $testPresentProperties) {

                It "Passes when access policy '$property' is correct" {
                    Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                    $testTargetResourceParams = $testAccessPolicy.Clone();
                    $testTargetResourceParams[$property] = $fakeResource[$property];

                    $result = Test-TargetResource @testTargetResourceParams;

                    $result | Should Be $true;
                }
            }

            $testAbsentProperties = @(
                'DeliveryGroup',
                'Enabled',
                'AllowRestart',
                'Name',
                'Description',
                'IncludeUsers',
                'ExcludeUsers'
            )
            foreach ($property in $testAbsentProperties) {

                It "Fails when access policy '$property' is incorrect" {
                    Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                    $testTargetResourceParams = $testAccessPolicy.Clone();

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
            It "Fails when access policy 'AccessType' parameter is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $testTargetResourceParams = $testAccessPolicy.Clone();
                $testTargetResourceParams['AccessType'] = 'Direct';

                $result = Test-TargetResource @testTargetResourceParams;

                $result | Should Be $false;
            }

            It "Fails when access policy 'Protocol' parameter is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $testTargetResourceParams = $testAccessPolicy.Clone();
                $testTargetResourceParams['Protocol'] = @('RDP');

                $result = Test-TargetResource @testTargetResourceParams;

                $result | Should Be $false;
            }

            It "Fails when access policy 'Ensure' parameter is incorrect" {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }
                $testTargetResourceParams = $testAccessPolicy.Clone();
                $testTargetResourceParams['Ensure'] = 'Absent';

                $result = Test-TargetResource @testTargetResourceParams;

                $result | Should Be $false;
            }
            #endregion ValidateSet parameters

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {

        } #end context Set-TargetResource {

    } #end describe XD7AccessPolicy

} #end inmodulescope
