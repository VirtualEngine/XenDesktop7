[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-DSWebReceiverAuthenticationMethods { }
    function Set-DSWebReceiverAuthenticationMethods { }

    Describe 'XenDesktop7\VE_XD7StoreFrontReceiverAuthenticationMethod' {

        $testStoreFrontReceiverAuthenticationMethod = @{
            VirtualPath = '/Citrix/Store';
            AuthenticationMethod = 'ExplicitForms','IntegratedWindows';
        };

        $stubDSWebReceiverAuthenticationMethods = 'ExplicitForms','CitrixFederation';
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Mock AssertXDModule;
        Mock FindXDModule { return $Name }
        Mock Import-Module;

        Context 'Get-TargetResource' {

            Mock Get-DSWebReceiverAuthenticationMethods;

            It 'Returns a System.Collections.Hashtable type' {
                Mock Get-DSWebReceiverAuthenticationMethods { return $stubDSWebReceiverAuthenticationMethods; }

                $targetResource = Get-TargetResource @testStoreFrontReceiverAuthenticationMethod;

                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Asserts "UtilsModule" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontReceiverAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'UtilsModule' } -Scope It;
            }

            It 'Asserts "WebReceiverModule" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontReceiverAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'WebReceiverModule' } -Scope It;
            }

            It 'Asserts "StoresModule" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontReceiverAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'StoresModule' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {


            It 'Returns True when authentication methods match' {
                Mock Get-TargetResource { return $testStoreFrontReceiverAuthenticationMethod; }

                Test-TargetResource @testStoreFrontReceiverAuthenticationMethod | Should Be $true;
            }

            It 'Returns False when authentication method is missing' {
                $testStoreFrontReceiverAuthenticationMethodMissing = @{
                    VirtualPath = '/Citrix/Store';
                    AuthenticationMethod = 'ExplicitForms';
                }
                Mock Get-TargetResource { return $testStoreFrontReceiverAuthenticationMethodMissing; }

                Test-TargetResource @testStoreFrontReceiverAuthenticationMethod | Should Be $false;
            }

            It 'Returns False when additional authentication method is present' {
                $testStoreFrontReceiverAuthenticationMethodMissing = @{
                    VirtualPath = '/Citrix/Store';
                    AuthenticationMethod = 'ExplicitForms','IntegratedWindows','HttpBasic';
                }
                Mock Get-TargetResource { return $testStoreFrontReceiverAuthenticationMethodMissing; }

                Test-TargetResource @testStoreFrontReceiverAuthenticationMethod | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {

            Mock Set-DSWebReceiverAuthenticationMethods;

            It 'Calls "Set-DSWebReceiverAuthenticationMethods" method' {
                $targetResource = Set-TargetResource @testStoreFrontReceiverAuthenticationMethod;

                Assert-MockCalled Set-DSWebReceiverAuthenticationMethods -Scope It;
            }

            It 'Asserts "UtilsModule" module is registered' {
                $targetResource = Set-TargetResource @testStoreFrontReceiverAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'UtilsModule' } -Scope It;
            }

            It 'Asserts "WebReceiverModule" module is registered' {
                $targetResource = Set-TargetResource @testStoreFrontReceiverAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'WebReceiverModule' } -Scope It;
            }

            It 'Asserts "StoresModule" module is registered' {
                $targetResource = Set-TargetResource @testStoreFrontReceiverAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'StoresModule' } -Scope It;
            }

        } #end Set-TargetResource

    } #end describe XD7Site
} #end inmodulescope
