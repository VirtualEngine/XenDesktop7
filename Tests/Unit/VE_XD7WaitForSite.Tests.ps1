[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    Describe 'XenDesktop7\VE_XD7WaitForSite' {

        Context 'TestXDSite' {

            function Get-XDSite {
                [CmdletBinding()]
                param ($AdminAddress)
            }

            Mock -CommandName Get-XDSite -MockWith { return @{ Name = 'TestSite' } }
            Mock -CommandName Import-Module { }
            Mock -CommandName Invoke-Command { }

            It 'Does not throw with a null $Credential parameter (#13)' {

                { TestXDSite -ExistingControllerName TestController -Credential $null } | Should Not Throw;
            }

        } #end context TestXDSite

    } #end describe XD7WaitForSite
} #end inmodulescope
