$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    $testResource = @{
        StoreName = 'TestStore'
        FarmName  = 'TestFarm'
    }

    $fakeResource = @{
        FriendlyName = $testResource.StoreName
        FarmName     = $testResource.FarmName
    }

     ## Stub functions
    function Get-STFStoreService { return $fakeResource }

    function Get-STFStoreFarm { }

    function Add-STFStoreFarm { }

    function Set-STFStoreFarm { }

    function Remove-STFStoreFarm { }

    Describe 'XenDesktop7\XD7StoreFrontStoreFarm' {

        # Guard mock
        Mock Import-Module { }

        Context 'Get-TargetResource' {

            It 'Returns a System.Collections.Hashtable type' {

                (Get-TargetResource @testResource) -is [System.Collections.Hashtable] | Should Be $true;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $testResource; }

                $result = Test-TargetResource @testResource;

                $result -is [System.Boolean] | Should Be $true;
            }


        } #end context Test-TargetResource

        Context 'Set-TargetResource' {

            It 'Does not throw' {

                { Set-TargetResource @testResource } | Should Not Throw;
            }

        } #end context Set-TargetResource {

    } #end describe

} #end inmodulescope
