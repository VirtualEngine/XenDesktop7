$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'VE_XD7Controller' {
    
    function Get-XDSite { }
    function Add-XDController { param ( $AdminAddress, $SiteControllerAddress ) }
    function Remove-XDController { param ( $ControllerName ) }

    Describe 'VE_XD7Controller' {

        $testControllerName = 'TestController';
        $testSite =  [PSCustomObject] @{ Name = 'TestSite'; Controllers = @( @{ DnsName = $testControllerName; }; ); }
        $testSiteControllerNonExistent =  [PSCustomObject] @{ Name = 'TestSite'; Controllers = @( @{ DnsName = "$($testControllerName)2"; }; ); }
        $testController = @{ SiteName = 'TestSite'; ExistingControllerName = $testControllerName; Ensure = 'Present'; }
        $testControllerNonExistent =  @{ SiteName = 'TestSite'; ExistingControllerName = $testControllerName; Ensure = 'Absent'; }
        $testControllerSiteNonExistent =  @{ SiteName = $null; ExistingControllerName = $testControllerName; Ensure = 'Absent'; }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
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
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testControllerWithCredentials = $testController.Clone();
                $testControllerWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testControllerWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.XenDesktop.Admin is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testController } | Should Throw;
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
            Mock -CommandName TestXDModule -MockWith { return $true; }
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
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testControllerWithCredentials = $testController.Clone();
                $testControllerWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testControllerWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Throws when Citrix.XenDesktop.Admin is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Set-TargetResource @testController } | Should Throw;
            }

        } #end context Set-TargetResource
    
    } #end describe XD7Controller
} #end inmodulescope
