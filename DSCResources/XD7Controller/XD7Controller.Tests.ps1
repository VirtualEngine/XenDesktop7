$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".");
. "$here\$sut";

## Dot source XD7Common functions
$moduleParent = Split-Path -Path $here -Parent;
Get-ChildItem -Path "$moduleParent\XD7Common" -Include *.ps1 -Exclude '*.Tests.ps1' -Recurse |
    ForEach-Object { . $_.FullName; }

function Get-XDSite {
    param ( $AdminAddress )
};

Describe 'XD7Controller\Get-TargetResource' {

    Mock -CommandName TestXDModule { return $true; }
    Mock -CommandName FindXDModule { return (Get-PSDrive -Name TestDrive).Root; };
    Mock -CommandName Import-Module { };

    It 'returns a System.Collections.Hashtable.' {
        $testSiteName = 'TestSite';
        $testControllerName = 'TestController';
        Mock -CommandName Get-XDSite -ParameterFilter { $AdminAddress -eq $testControllerName } -MockWith {
            return @{
                Name = $testSiteName;
                Controllers = @( @{ DnsName = $testControllerName; }; )
            }
        }
        $targetResource = Get-TargetResource -SiteName $testSiteName -ControllerName $testControllerName;
        $targetResource -is [System.Collections.Hashtable] | Should Be $true;
        Assert-MockCalled -CommandName Get-XDSite -Exactly 1;
    }

} #end describe XD7Controller\Get-TargetResource

<#
ControllerState    : Active
ControllerVersion  : 7.6.0.5024
DesktopsRegistered : 1
DnsName            : XD76XC.lab.local
LastActivityTime   : 11/05/2015 09:55:18
LastStartTime      : 07/05/2015 15:29:53
MachineName        : LAB\XD76XC
OSType             : Windows 2012 R2
OSVersion          : 6.2.9200.0
Sid                : S-1-5-21-4119761346-2640891843-1747844263-1110

-ParameterFilter { $AdminAddress -eq 'TestController' } 
-ParameterFilter { $SiteName -eq $testSiteName -and $ControllerName -eq $testControllerName }
#>