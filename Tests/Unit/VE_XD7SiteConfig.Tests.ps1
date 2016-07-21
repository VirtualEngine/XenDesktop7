[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
$moduleRoot = Split-Path -Path (Split-Path -Path $here -Parent) -Parent;
Import-Module (Join-Path $moduleRoot -ChildPath "\DSCResources\$sut\$sut.psm1") -Force;

InModuleScope $sut {

    function Get-BrokerSite { }

    Describe 'XenDesktop7\VE_XD7SiteConfig' {

        $testSiteConfig = @{
            IsSingleInstance = 'Yes';
            TrustRequestsSentToTheXmlServicePort = $false;
            SecureIcaRequired = $false;
            DnsResolutionEnabled = $false;
            ConnectionLeasingEnabled = $true;
        };

        $stubSiteConfig = [PSCustomObject] @{
            TrustRequestsSentToTheXmlServicePort = $false;
            SecureIcaRequired = $false;
            DnsResolutionEnabled = $false;
            BaseOU = [System.Guid]::NewGuid().ToString();
            ConnectionLeasingEnabled = $true;
            Name = 'TestSite';
        };
        $testCredential = [System.Management.Automation.PSCredential]::Empty;

        Context 'Get-TargetResource' {
            Mock AssertXDModule { }
            Mock Add-PSSnapin;

            It 'Returns a System.Collections.Hashtable type' {
                Mock Get-BrokerSite { return $stubSiteConfig; }

                $targetResource = Get-TargetResource @testSiteConfig;

                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Mock Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null }

                $targetResource = Get-TargetResource @testSiteConfig;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' }

                $testSiteWithCredential = $testSiteConfig.Clone();
                $testSiteWithCredential['Credential'] = $testCredential;

                $targetResource = Get-TargetResource @testSiteWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" module is registered' {
                $targetResource = Get-TargetResource @testSiteConfig;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -Scope It;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock Get-TargetResource { return $testSiteConfig; }

            It 'Returns True when all properties match' {
                Test-TargetResource @testSiteConfig | Should Be $true;
            }

            $properties = @(
                'TrustRequestsSentToTheXmlServicePort',
                'SecureIcaRequired',
                'DnsResolutionEnabled',
                'ConnectionLeasingEnabled'
            )

            foreach ($property in $properties) {

                It "Returns False when `"$property`" is incorrect" {
                    $testSiteConfigCustom = $testSiteConfig.Clone();
                    $testSiteConfigCustom[$property] = -not $testSiteConfigCustom[$property];

                    Test-TargetResource @testSiteConfigCustom | Should Be $false;
                }
            }

            It 'Returns False when "BaseOU" is incorrect' {
                $testSiteConfigCustom = $testSiteConfig.Clone();
                $testSiteConfigCustom['BaseOU'] = 'IncorrectGuid';

                Test-TargetResource @testSiteConfigCustom | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock AssertXDModule { };
            Mock Add-PSSnapin;

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }

                Set-TargetResource @testSiteConfig;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } { }
                $testSiteConfigWithCredential = $testSiteConfig.Clone();
                $testSiteConfigWithCredential['Credential'] = $testCredential;

                Set-TargetResource @testSiteConfigWithCredential;

                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredential -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }

            It 'Asserts "Citrix.Broker.Admin.V2" module is registered' {
                Set-TargetResource @testSiteConfig;

                Assert-MockCalled AssertXDModule -ParameterFilter { $Name -eq 'Citrix.Broker.Admin.V2' } -Scope It;
            }

        } #end Set-TargetResource

    } #end describe XD7Site
} #end inmodulescope
