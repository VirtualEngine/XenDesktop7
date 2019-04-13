[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-DSFrameworkProperty { }
    function Set-DSClusterAddress { }

    Describe 'XenDesktop7\VE_XD7StoreFrontBaseUrl' {

        $testStoreFrontBaseUrl = @{
            BaseUrl = 'http://storefront.test.local/';
        };

        $stubDSFrameworkProperty = 'http://storefront.test.local/';

        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {

            Mock AssertXDModule;
            Mock Add-PSSnapIn;

            It 'Returns a System.Collections.Hashtable type' {
                Mock Get-DSFrameworkProperty { return $stubDSFrameworkProperty; }

                $targetResource = Get-TargetResource @testStoreFrontBaseUrl;

                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Asserts "Citrix.DeliveryServices.Framework.Commands" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontBaseUrl;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'Citrix.DeliveryServices.Framework.Commands' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            Mock Get-TargetResource { return $testStoreFrontBaseUrl; }

            It 'Returns True when "BaseUrl" with trailing slash matches' {
                Test-TargetResource @testStoreFrontBaseUrl | Should Be $true;
            }

            It 'Returns True when "BaseUrl" without trailing slash matches' {

                $testStoreFrontBaseUrlNoSlash = @{
                    BaseUrl = 'http://storefront.test.local';
                };

                Test-TargetResource @testStoreFrontBaseUrlNoSlash | Should Be $true;
            }

            It 'Returns False when "BaseUrl" does not matches' {
                Test-TargetResource -BaseUrl 'https://storefront.test.local' | Should Be $false;
            }


        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock AssertXDModule { };
            Mock FindXDModule { return $Name }
            Mock Import-Module;
            Mock Set-DSClusterAddress;

            It 'Calls "Set-DSWebReceiverAuthenticationMethods" method' {
                Set-TargetResource @testStoreFrontBaseUrl;

                Assert-MockCalled Set-DSClusterAddress -Scope It;
            }

            It 'Asserts "UtilsModule" module is registered' {
                Set-TargetResource @testStoreFrontBaseUrl;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'UtilsModule' } -Scope It;
            }

            It 'Asserts "ClusterConfigurationModule" module is registered' {
                Set-TargetResource @testStoreFrontBaseUrl;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'ClusterConfigurationModule' } -Scope It;
            }

        } #end Set-TargetResource #>

        AfterAll {

            Remove-Item -Path Function:\Write-Host -ErrorAction SilentlyContinue
        }

    } #end describe

} #end inmodulescope
