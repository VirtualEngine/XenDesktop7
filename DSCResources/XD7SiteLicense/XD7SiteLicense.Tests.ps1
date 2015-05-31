$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '.psm1')
Import-Module (Join-Path $here -ChildPath $sut) -Force;

InModuleScope 'XD7SiteLicense' {

    function Get-SiteConfig { }
    function Set-ConfigSite { param ( $LicenseServerName, $LicenseServerPort, $ProductEdition, $LicensingModel ) }
    function Get-LicCertificate { }
    function Set-ConfigSiteMetadata { param ( $Name, $Value ) }

    Describe 'XD7SiteLicense' {

        $testSiteLicense = @{
            LicenseServer = 'TestLicenseServer';
        };
        $stubSiteLicense = [PSCustomObject] @{
            LicenseServerName = 'TestLicenseServer';
            LicenseServerPort = 27000;
            ProductEdition = 'PLT'; # PLT, ENT, APP
            LicensingModel = 'UserDevice'; # UserDevice, Concurrent
            MetaDataMap = @{ CertificateHash ='MyTestCertificateHash'; }
        };
        $targetResource = @{
            LicenseServer = $stubSiteLicense.LicenseServerName;
            LicenseServerPort = $stubSiteLicense.LicenseServerPort;
            LicenseEdition = $stubSiteLicense.ProductEdition;
            LicenseModel = $stubSiteLicense.LicensingModel;
            TrustLicenseServerCertificate = $true;
        }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; };
            Mock -CommandName Add-PSSnapin -MockWith { };
            Mock -CommandName Get-SiteConfig -MockWith { return $stubSiteLicense; };

            It 'Returns a System.Collections.Hashtable type' {
                (Get-TargetResource @testSiteLicense) -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testSiteLicense;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testSiteLicenseWithCredentials = $testSiteLicense.Clone();
                $testSiteLicenseWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testSiteLicenseWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Configuration.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testSiteLicense } | Should Throw;
            }
            
        } #end context Get-TargetResource

        Context 'Test-TargetResource' {
            Mock -CommandName Get-TargetResource -MockWith { return $TargetResource; }

            It 'Returns True when all properties match' {
                Test-TargetResource @testSiteLicense | Should Be $true;
            }
            
            It 'Returns False when "LicenseServer" is incorrect' {
                Test-TargetResource -LicenseServer 'CustomServer' | Should Be $false;
            }

            It 'Returns False when "LicenseServer" is incorrect' {
                Test-TargetResource @testSiteLicense -LicenseServerPort 27001 | Should Be $false;
            }

            It 'Returns False when "LicenseEdition" is incorrect' {
                Test-TargetResource @testSiteLicense -LicenseEdition ENT | Should Be $false;
            }

            It 'Returns False when "LicensingModel" is incorrect' {
                Test-TargetResource @testSiteLicense -LicenseModel Concurrent | Should Be $false;
            }

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; };
            Mock -CommandName Add-PSSnapin -MockWith { };
            Mock -CommandName Get-SiteConfig -MockWith { return $stubSiteLicense; }; 

            It 'Calls "Set-SiteConfig"' {
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                $filter = {
                    ($LicenseServerName -eq $targetResource.LicenseServer) -and
                    ($LicenseServerPort -eq $targetResource.LicenseServerPort) -and
                    ($ProductEdition -eq $targetResource.LicenseEdition) -and 
                    ($LicensingModel -eq $targetResource.LicenseModel)
                }
                Mock -CommandName Set-ConfigSite -ParameterFilter $filter -MockWith { };
                Set-TargetResource @testSiteLicense -TrustLicenseServerCertificate $false;
                Assert-MockCalled -CommandName Set-ConfigSite -Exactly 1 -Scope It -ParameterFilter $filter;
            }

            It 'Calls "Set-SiteConfigMetadata" when "TrustLicenseServerCertificate" = "True"' {
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Mock -CommandName Get-LicCertificate -MockWith { return [PSCustomObject] @{ CertHash = 'MyTestCertificateHash';  }}
                Mock -CommandName Set-ConfigSiteMetadata -ParameterFilter { $Name -eq 'CertificateHash' -and $Value -eq 'MyTestCertificateHash' } -MockWith { }
                Set-TargetResource @testSiteLicense -TrustLicenseServerCertificate $true;
                Assert-MockCalled -CommandName Set-ConfigSiteMetadata -Exactly 1 -Scope It -ParameterFilter { $Name -eq 'CertificateHash' -and $Value -eq 'MyTestCertificateHash' }
            }

            It 'Does not call "Set-SiteConfigMetadata" when "TrustLicenseServerCertificate" = "False"' {
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Mock -CommandName Set-ConfigSiteMetadata -MockWith { }
                Set-TargetResource @testSiteLicense -TrustLicenseServerCertificate $false;
                Assert-MockCalled -CommandName Set-ConfigSiteMetadata -Exactly 0 -Scope It;
            }

            It 'Invokes script block without credentials by default' {
                #Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Set-TargetResource @testSiteLicense;
                #Assert-MockCalled Invoke-Command -Exactly 1 -Scope It;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testSiteLicenseWithCredentials = $testSiteLicense.Clone();
                $testSiteLicenseWithCredentials['Credential'] = $testCredentials;
                Set-TargetResource @testSiteLicenseWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Configuration.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Set-TargetResource @testSiteLicense } | Should Throw;
            }

        } #end context Set-TargetResource

    } #end describe XD7SiteLicense
} #end inmodulescope