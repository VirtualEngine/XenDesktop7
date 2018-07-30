[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerDesktopGroup { }
    function Get-BrokerApplication { }
    function New-BrokerApplication { param ($ApplicationType) }
    function Set-BrokerApplication { }
    function Remove-BrokerApplication { }
    function Get-CtxIcon { }
    function New-BrokerIcon { }

    Describe 'XenDesktop7\VE_XD7DesktopGroupApplication' {

        $testDesktopGroupName = 'TestGroup';
        $fakeBrokerGroup = @{
            Name = $testDesktopGroupName;
            Uid = 42;
        };
        $testApplicationName = 'Test Application';
        $testApplicationWorkingDirectory = (Get-PSDrive -Name TestDrive).Root;
        $testApplicationPath = Join-Path -Path $testApplicationWorkingDirectory -ChildPath "$testApplicationName.exe";
        $testApplication = @{
            Name = $testApplicationName;
            Path = $testApplicationPath;
            DesktopGroupName = $testDesktopGroupName;

        }
        $fakeApplication = @{
            Name = $testApplicationName;
            Path = $testApplicationPath
            DesktopGroupName = $testDesktopGroupName;
            ApplicationType = 'HostedOnDesktop';
            Arguments = '/testargument';
            WorkingDirectory = $testApplicationWorkingDirectory;
            Description = 'My Test Application';
            DisplayName = $testApplicationName;
            Enabled = $true;
            Visible = $true;
            Ensure = 'Present';
        }
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };
            Mock -CommandName Add-PSSnapin -MockWith { };
            Mock -CommandName InvokeScriptBlock -MockWith { & $ScriptBlock; };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Get-BrokerDesktopGroup { return $fakeBrokerGroup; }
                #Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }

                $targetResource = Get-TargetResource @testApplication;
                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                #Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                $null = Get-TargetResource @testApplication;

                Assert-MockCalled InvokeScriptBlock -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testApplicationWithCredential = $testApplication.Clone();
                $testApplicationWithCredential['Credential'] = $testCredential;

                $null = Get-TargetResource @testApplicationWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" is registered' {
                $null = Get-TargetResource @testApplication

                Assert-MockCalled AssertXDModule -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName Get-TargetResource -MockWith { return $fakeApplication }

            It 'Returns a System.Boolean type' {
                (Test-TargetResource @testApplication) -is [System.Boolean] | Should Be $true;
            }

            It 'Returns True when all properties match' {
                Test-TargetResource @testApplication | Should Be $true;
            }

            It 'Returns False when "Ensure" is incorrect' {
                Test-TargetResource @testApplication -Ensure Absent | Should Be $false;
            }

            ## String parameters
            $stringParameters = 'Path','DesktopGroupName','Arguments','WorkingDirectory','Description','DisplayName';
            foreach ($parameter in $stringParameters) {
                It "Returns False when '$parameter' is incorrect" {
                    $targetResource = $testApplication.Clone();
                    $targetResource[$parameter] = 'Incorrect';

                    Test-TargetResource @targetResource | Should Be $false;
                }
            }

            It 'Returns False when "Enabled" is incorrect' {
                Test-TargetResource @testApplication -Enabled $false | Should Be $false;
            }

            It 'Returns False when "Visible" is incorrect' {
                Test-TargetResource @testApplication -Visible $false | Should Be $false;
            }

            It 'Does not throw when immutable "ApplicationType" property is specified but application does not exist' {
                Mock Get-TargetResource -MockWith { return @{ Ensure = 'Absent'; ApplicationType = 'HostedOnDesktop'; } }

                { Test-TargetResource @testApplication -ApplicationType 'InstalledOnClient' } | Should Not Throw;
            }

            It 'Throws when immutable "ApplicationType" property is specified' {
                Mock Get-TargetResource -MockWith { return @{ Ensure = 'Present'; ApplicationType = 'HostedOnDesktop'; } }

                { Test-TargetResource @testApplication -ApplicationType 'InstalledOnClient' } | Should Throw 'ApplicationType';
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName AssertXDModule -MockWith { };
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Calls "New-BrokerApplication" when "Ensure" = "Present" and application does not exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $fakeBrokerGroup };
                Mock -CommandName New-BrokerApplication -MockWith { };
                Mock -CommandName Get-CtxIcon -MockWith { };
                Mock -CommandName InvokeScriptBlock -MockWith { & $ScriptBlock; };

                Set-TargetResource @testApplication;

                Assert-MockCalled -CommandName New-BrokerApplication -Exactly 1 -Scope It;
            }

            It 'Calls "New-BrokerApplication" with specified application type' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $fakeBrokerGroup }
                Mock -CommandName New-BrokerApplication -ParameterFilter { $ApplicationType -eq 'InstalledOnClient' } -MockWith { }
                Mock -CommandName Get-CtxIcon -MockWith { }

                Set-TargetResource -ApplicationType 'InstalledOnClient' @testApplication;

                Assert-MockCalled -CommandName New-BrokerApplication -ParameterFilter { $ApplicationType -eq 'InstalledOnClient' } -Exactly 1 -Scope It;
            }

            It 'Calls "Set-BrokerApplication" when "Ensure" = "Present" and application exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $fakeBrokerGroup }
                Mock -CommandName Get-BrokerApplication -MockWith { return  $fakeApplication }
                Mock -CommandName Set-BrokerApplication -MockWith { }

                Set-TargetResource @testApplication;

                Assert-MockCalled -CommandName Set-BrokerApplication -Exactly 1 -Scope It;
            }

            It 'Calls "Remove-BrokerApplication" when "Ensure" = "Absent" and application exists' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $fakeBrokerGroup }
                Mock -CommandName Get-BrokerApplication -MockWith { return  $fakeApplication }
                Mock -CommandName Remove-BrokerApplication -MockWith { }

                Set-TargetResource @testApplication -Ensure Absent;

                Assert-MockCalled -CommandName Remove-BrokerApplication -Exactly 1 -Scope It;
            }

            It 'Does not call "Remove-BrokerApplication" when "Ensure" = "Absent" and application does not exist' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $fakeBrokerGroup }
                Mock -CommandName Get-BrokerApplication -MockWith { }
                Mock -CommandName Remove-BrokerApplication -MockWith { }

                Set-TargetResource @testApplication -Ensure Absent;

                Assert-MockCalled -CommandName Remove-BrokerApplication -Exactly 0 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $fakeBrokerGroup }
                Mock -CommandName Get-BrokerApplication -MockWith { return  $fakeApplication }

                Set-TargetResource @testApplication;

                Assert-MockCalled InvokeScriptBlock -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Get-BrokerDesktopGroup -MockWith { return $fakeBrokerGroup }
                Mock -CommandName Get-BrokerApplication -MockWith { return  $fakeApplication }
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testApplicationWithCredential = $testApplication.Clone();
                $testApplicationWithCredential['Credential'] = $testCredential;

                Set-TargetResource @testApplicationWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -MockWith { }

                Set-TargetResource @testApplication

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -Scope It;
            }

            It 'Asserts "Citrix.Common.Commands" is registered' {
                Mock AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Common.Commands' } -MockWith { }

                Set-TargetResource @testApplication

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Common.Commands' } -Scope It;
            }

        } #end context Set-TargetResource

    } #end describe XD7DesktopGroupApplication
} #end inmodulescope
