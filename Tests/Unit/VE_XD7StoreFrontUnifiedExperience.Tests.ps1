[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-DSUnifiedExperienceEndpointsForStore { }
    function Set-DSUnifiedExperienceEndpointsForStore { }
    function Remove-DSUnifiedExperienceEndpointsForStore { }

    Describe 'XenDesktop7\VE_XD7StoreFrontUnifiedExperience' {

        $testStoreFrontUnifiedExperience = @{
            VirtualPath = '/Citrix/Store';
            WebReceiverVirtualPath = '/Citrix/StoreWeb'
        };

        $stubDSUnifiedExperienceEndpointsForStore = [PSCustomObject] @{
            EndpointSite = '/Citrix/StoreWeb';
        }

        Mock AssertXDModule;
        Mock FindXDModule { return $Name }
        Mock Import-Module;

        Context 'Get-TargetResource' {

            Mock Get-DSUnifiedExperienceEndpointsForStore { return $stubDSUnifiedExperienceEndpointsForStore; }

            It 'Returns a System.Collections.Hashtable type' {
                $targetResource = Get-TargetResource @testStoreFrontUnifiedExperience;

                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Asserts "UtilsModule" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontUnifiedExperience;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'UtilsModule' } -Scope It;
            }

            It 'Asserts "FarmsModule" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontUnifiedExperience;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'FarmsModule' } -Scope It;
            }

            It 'Asserts "StoresModule" module is registered' {
                $targetResource = Get-TargetResource @testStoreFrontUnifiedExperience;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'StoresModule' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            It 'Returns True when unified experience is enabled on the store and Ensure is "Present"' {
                Mock Get-TargetResource { return $testStoreFrontUnifiedExperience; }

                Test-TargetResource @testStoreFrontUnifiedExperience | Should Be $true;
            }

            It 'Returns True when unified experience is disabled on the store and Ensure is "Absent"' {
                Mock Get-TargetResource { return @{ VirtualPath = '/Citrix/Store'; WebReceiverVirtualPath = $null; } }

                Test-TargetResource @testStoreFrontUnifiedExperience -Ensure Absent | Should Be $true;
            }

            It 'Returns False when unified experience is disabled on the store and Ensure is "Present"' {
                Mock Get-TargetResource { return @{ VirtualPath = '/Citrix/Store'; WebReceiverVirtualPath = $null; } }

                Test-TargetResource @testStoreFrontUnifiedExperience | Should Be $false;
            }

            It 'Returns False when unified experience is enabled on the store and Ensure is "Absent"' {
                Mock Get-TargetResource { return $testStoreFrontUnifiedExperience; }

                Test-TargetResource @testStoreFrontUnifiedExperience -Ensure Absent | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {

            Mock Set-DSUnifiedExperienceEndpointsForStore;
            Mock Remove-DSUnifiedExperienceEndpointsForStore;

            It 'Calls "Set-DSUnifiedExperienceEndpointsForStore" method when Ensure is "Present"' {
                $targetResource = Set-TargetResource @testStoreFrontUnifiedExperience -Ensure Present;

                Assert-MockCalled Set-DSUnifiedExperienceEndpointsForStore -Scope It;
            }

            It 'Calls "Remove-DSUnifiedExperienceEndpointsForStore" method when Ensure is "Absent"' {
                $targetResource = Set-TargetResource @testStoreFrontUnifiedExperience -Ensure Absent;

                Assert-MockCalled Remove-DSUnifiedExperienceEndpointsForStore -Scope It;
            }

            It 'Asserts "UtilsModule" module is registered' {
                $targetResource = Set-TargetResource @testStoreFrontUnifiedExperience;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'UtilsModule' } -Scope It;
            }

            It 'Asserts "WebReceiverModule" module is registered' {
                $targetResource = Set-TargetResource @testStoreFrontUnifiedExperience;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'WebReceiverModule' } -Scope It;
            }

            It 'Asserts "StoresModule" module is registered' {
                $targetResource = Set-TargetResource @testStoreFrontUnifiedExperience;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -contains 'StoresModule' } -Scope It;
            }

        } #end Set-TargetResource

    } #end describe XD7Site
} #end inmodulescope
