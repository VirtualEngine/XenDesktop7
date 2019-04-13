[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-DSAuthenticationProtocolsDeployed { }
    function Add-DSAuthenticationProtocolsDeployed { }
    function Remove-DSAuthenticationProtocolsDeployed { }

    Describe 'XenDesktop7\VE_StoreFrontAuthenticationMethod' {

        $testStoreFrontAuthenticationMethod = @{
            VirtualPath = '/Citrix/Store';
            AuthenticationMethod = 'ExplicitForms','IntegratedWindows';
        };

        $stubDSAuthenticationProtocolsDeployed = 'ExplicitForms','CitrixFederation';
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Mock AssertXDModule;
        Mock FindXDModule { return $Name }
        Mock Import-Module;

        Context 'Get-TargetResource' {

            Mock Get-DSAuthenticationProtocolsDeployed { return $stubDSAuthenticationProtocolsDeployed; }

            It 'Returns a System.Collections.Hashtable type' {
                $targetResource = Get-TargetResource @testStoreFrontAuthenticationMethod;

                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Asserts "UtilsModule" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'UtilsModule' } -Scope It;
            }

            It 'Asserts "AuthenticationModule" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'AuthenticationModule' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            It 'Returns True when authentication methods match' {
                Mock Get-TargetResource { return $testStoreFrontAuthenticationMethod; }

                Test-TargetResource @testStoreFrontAuthenticationMethod | Should Be $true;
            }

            It 'Returns False when authentication method is missing' {
                $testStoreFrontAuthenticationMethodMissing = @{
                    VirtualPath = '/Citrix/Store';
                    AuthenticationMethod = 'IntegratedWindows';
                }
                Mock Get-TargetResource { return $testStoreFrontAuthenticationMethodMissing; }

                Test-TargetResource @testStoreFrontAuthenticationMethod | Should Be $false;
            }

            It 'Returns False when additional authentication method is present' {
                $testStoreFrontAuthenticationMethodMissing = @{
                    VirtualPath = '/Citrix/Store';
                    AuthenticationMethod = 'ExplicitForms','HttpBasic';
                }
                Mock Get-TargetResource { return $testStoreFrontAuthenticationMethodMissing; }

                Test-TargetResource @testStoreFrontAuthenticationMethod | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {

            Mock Add-DSAuthenticationProtocolsDeployed;
            Mock Remove-DSAuthenticationProtocolsDeployed

            It 'Calls "Add-DSAuthenticationProtocolsDeployed" method when Ensure is "Present"' {
                $targetResource = Set-TargetResource @testStoreFrontAuthenticationMethod -Ensure Present;

                Assert-MockCalled Add-DSAuthenticationProtocolsDeployed -Scope It;
            }

            It 'Calls "Remove-DSAuthenticationProtocolsDeployed" method when Ensure is "Absent"' {
                $targetResource = Set-TargetResource @testStoreFrontAuthenticationMethod -Ensure Absent;

                Assert-MockCalled Remove-DSAuthenticationProtocolsDeployed -Scope It;
            }

            It 'Asserts "UtilsModule" module is registered' {
                $targetResource = Set-TargetResource @testStoreFrontAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'UtilsModule' } -Scope It;
            }

            It 'Asserts "AuthenticationModule" module is registered' {
                $targetResource = Set-TargetResource @testStoreFrontAuthenticationMethod;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'AuthenticationModule' } -Scope It;
            }

        } #end Set-TargetResource #>

        AfterAll {

            Remove-Item -Path Function:\Write-Host -ErrorAction SilentlyContinue
        }

    } #end describe

} #end inmodulescope
