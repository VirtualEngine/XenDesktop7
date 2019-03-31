$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

     ## Stub functions
    function Get-STFStoreService { }

    function Get-STFStoreFarm { }

    function Get-STFAuthenticationService { }

    function Add-STFAuthenticationService { }

    function Set-STFStoreService { }

    function Set-STFStoreFarm { }

    function New-STFStoreFarm { }

    function Add-STFStoreService { }

    function Remove-STFAuthenticationService { }

    function Remove-STFStoreService { }


    Describe 'XenDesktop7\VE_XD7StoreFrontStore' {

        # Guard mock
        Mock Import-Module { }

        $testResource = @{
            StoreName = 'Store';
            AuthType  = 'Explicit';
            Servers   = 'Server1', 'Server2';
        }

        $fakeResource = @{
            StoreName = 'Store';
            AuthType  = 'Explicit';
            Servers   = 'Server1', 'Server2';
        }

        Context 'Get-TargetResource' {

            It 'Returns a System.Collections.Hashtable type' {

                (Get-TargetResource @testResource) -is [System.Collections.Hashtable] | Should Be $true;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeResource; }

                $result = Test-TargetResource @testResource;

                $result -is [System.Boolean] | Should Be $true;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {

            It 'Does not throw' {

                { Set-TargetResource @testResource } | Should Not Throw;
            }

        } #end context Set-TargetResource

    } #end describe

} #end inmodulescope
