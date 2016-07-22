[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-XDSite { }
    function Add-XDController { param ( $AdminAddress, $SiteControllerAddress ) }
    function Remove-XDController { param ( $ControllerName ) }

    Describe 'XenDesktop7\VE_XD7Controller' {

        $testControllerName = 'TestController';
        $testSite =  [PSCustomObject] @{ Name = 'TestSite'; Controllers = @( @{ DnsName = $testControllerName; }; ); }
        $testSiteControllerNonExistent =  [PSCustomObject] @{ Name = 'TestSite'; Controllers = @( @{ DnsName = "$($testControllerName)2"; }; ); }
        $testController = @{ SiteName = 'TestSite'; ExistingControllerName = $testControllerName; Ensure = 'Present'; }
        $testControllerNonExistent =  @{ SiteName = 'TestSite'; ExistingControllerName = $testControllerName; Ensure = 'Absent'; }
        $testControllerSiteNonExistent =  @{ SiteName = $null; ExistingControllerName = $testControllerName; Ensure = 'Absent'; }
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule { };
            Mock -CommandName Import-Module { };
            Mock -CommandName GetHostName -MockWith { return $testControllerName; }

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-XDSite { return $testSite; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                (Get-TargetResource @testController) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Returns "Present" when controller exists and "Ensure" = "Present" is specified' {
                Mock -CommandName Get-XDSite { return $testSite; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                $targetResource = Get-TargetResource @testController;

                $targetResource['Ensure'] | Should Be 'Present';
            }

            It 'Returns "Absent" when controller does not exist and "Ensure" = "Present" is specified' {
                Mock -CommandName Get-XDSite { return $testSiteControllerNonExistent; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                $targetResource = Get-TargetResource @testController;

                $targetResource['Ensure'] | Should Be 'Absent';
            }

            It 'Returns "Present" when controller exists and "Ensure" = "Absent" is specified' {
                Mock -CommandName Get-XDSite { return $testSite; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                $targetResource = Get-TargetResource @testControllerNonExistent;

                $targetResource['Ensure'] | Should Be 'Present';
            }

            It 'Returns "Absent" when controller does not exist and "Ensure" = "Absent" is specified' {
                Mock -CommandName Get-XDSite { return $testSiteControllerNonExistent; }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                $targetResource = Get-TargetResource @testControllerNonExistent;

                $targetResource['Ensure'] | Should Be 'Absent';
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                Get-TargetResource @testController;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testControllerWithCredential = $testController.Clone();
                $testControllerWithCredential['Credential'] = $testCredential;

                Get-TargetResource @testControllerWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.XenDesktop.Admin" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -MockWith { }

                Get-TargetResource @testController;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName GetHostName -MockWith { return $testControllerName; }

            It 'Returns a System.Boolean type' {
                Mock -CommandName Get-TargetResource -MockWith { return $testController; }

                (Test-TargetResource @testController) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when controller exists in site' {
                Mock -CommandName Get-TargetResource -MockWith { return $testController; }

                Test-TargetResource @testController | Should Be $true;
            }

            It 'Returns False when site does not exist' {
                Mock -CommandName Get-TargetResource -MockWith { return $testControllerSiteNonExistent; }

                Test-TargetResource @testController | Should Be $false;
            }

            It 'Returns False when controller does not exist in site' {
                Mock -CommandName Get-TargetResource -MockWith { return $testControllerNonExistent; }

                Test-TargetResource @testController | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName AssertXDModule -ParameterFilter { $IsSnapin -eq $false } -MockWith { }
            Mock -CommandName Import-Module { };
            Mock -CommandName GetHostName -MockWith { return $testControllerName; }

            It 'Calls Add-XDController when "Ensure" = "Present"' {
                Mock -CommandName Add-XDController -ParameterFilter { $AdminAddress -eq $testControllerName } -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                Set-TargetResource @testController;

                Assert-MockCalled -CommandName Add-XDController -ParameterFilter { $AdminAddress -eq $testControllerName } -Exactly 1 -Scope It;
            }

            It 'Calls Remove-XDController when "Ensure" = "Absent"' {
                Mock -CommandName Remove-XDController -ParameterFilter { $ControllerName -eq $testControllerName } -MockWith { }
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                Set-TargetResource @testControllerNonExistent;

                Assert-MockCalled -CommandName Remove-XDController -ParameterFilter { $ControllerName -eq $testControllerName } -Exactly 1 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                Set-TargetResource @testController;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testControllerWithCredential = $testController.Clone();
                $testControllerWithCredential['Credential'] = $testCredential;

                Set-TargetResource @testControllerWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin" module is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -MockWith { }

                Set-TargetResource @testControllerNonExistent;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.XenDesktop.Admin' } -Scope It;
            }


        } #end context Set-TargetResource

    } #end describe XD7Controller
} #end inmodulescope
