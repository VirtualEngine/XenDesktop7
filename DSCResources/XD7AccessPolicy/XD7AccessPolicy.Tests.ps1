$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')
Import-Module (Join-Path $here -ChildPath "$sut.psm1") -Force;

InModuleScope 'XD7AccessPolicy' {
    
    function Get-BrokerDesktopGroup { }
    function Get-BrokerAccessPolicyRule { }
    
    Describe 'XD7AccessPolicy' {

        $testDeliveryGroupName = 'Test Delivery Group';
        $testAccessPolicy = @{
            DeliveryGroup = $testDeliveryGroupName;
            AccessType = 'AccessGateway';
        }
        $testCredentials = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);

        Context 'Get-TargetResource' {
            Mock -CommandName TestXDModule -MockWith { return $true; }
            Mock -CommandName Add-PSSnapin -MockWith { };

            It 'Returns a System.Collections.Hashtable type' {
                Mock -CommandName Invoke-Command -MockWith { & $ScriptBlock; }
                (Get-TargetResource @testAccessPolicy) -is [System.Collections.Hashtable] | Should Be $true;
            }

             It 'Invokes script block without credentials by default' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } { }
                Get-TargetResource @testAccessPolicy;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $null -and $Authentication -eq $null } -Exactly 1 -Scope It;
            }

            It 'Invokes script block with credentials and CredSSP when specified' {
                Mock -CommandName Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } { }
                $testAccessPolicyWithCredentials = $testAccessPolicy.Clone();
                $testAccessPolicyWithCredentials['Credential'] = $testCredentials;
                Get-TargetResource @testAccessPolicyWithCredentials;
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -eq $testCredentials -and $Authentication -eq 'CredSSP' } -Exactly 1 -Scope It;
            }
            
            It 'Throws when Citrix.Broker.Admin.V2 is not registered' {
                Mock -CommandName TestXDModule -MockWith { return $false; }
                { Get-TargetResource @testAccessPolicy } | Should Throw;
            }

        } #end context Get-TargetResource

        Context 'Test-TargetResource' {

        } #end context Test-TargetResource

        Context 'Set-TargetResource' {

        } #end context Set-TargetResource {

    } #end describe XD7AccessPolicy

} #end inmodulescope