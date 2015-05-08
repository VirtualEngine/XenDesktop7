$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".");
. "$here\$sut";

## Dot source XD7Common functions
$moduleParent = Split-Path -Path $here -Parent;
Get-ChildItem -Path "$moduleParent\XD7Common" -Include *.ps1 -Exclude '*.Tests.ps1' -Recurse |
    ForEach-Object { . $_.FullName; }

Describe 'cXD7VDAController\Test-TargetResource' {

    Context 'Ensure Present' {

        It 'returns $true when DDC exists with single DDC.' {
            Mock -CommandName GetRegistryValue -MockWith { return 'ddc1'; }
            Test-TargetResource -Name 'ddc1' -Ensure 'Present' | Should Be $true;
        }

        It 'returns $true when DDC exists with mulitple DDCs.' {
            Mock -CommandName GetRegistryValue -MockWith { return 'ddc1 ddc2'; }
            Test-TargetResource -Name 'ddc1' -Ensure 'Present' | Should Be $true;
        }

        It 'returns $false when DDC does not exist with single DDCs.' {
            Mock -CommandName GetRegistryValue -MockWith { return 'ddc2'; }
            Test-TargetResource -Name 'ddc1' -Ensure 'Present' | Should Be $false;
        }

        It 'returns $false when DDC does not exist with mulitple DDCs.' {
            Mock -CommandName GetRegistryValue -MockWith { return 'ddc1 ddc2'; }
            Test-TargetResource -Name 'ddc3' -Ensure 'Present' | Should Be $false;
        }

    } #end context ensure present

    Context 'Ensure Absent' {

        It 'returns $false when DDC exists with single DDC.' {
            Mock -CommandName GetRegistryValue -MockWith { return 'ddc1'; }
            Test-TargetResource -Name 'ddc1' -Ensure 'Absent' | Should Be $false;
        }

        It 'returns $false when DDC exists with mulitple DDCs.' {
            Mock -CommandName GetRegistryValue -MockWith { return 'ddc1 ddc2'; }
            Test-TargetResource -Name 'ddc1' -Ensure 'Absent' | Should Be $false;
        }

        It 'returns $true when DDC does not exist with single DDCs.' {
            Mock -CommandName GetRegistryValue -MockWith { return 'ddc2'; }
            Test-TargetResource -Name 'ddc1' -Ensure 'Absent' | Should Be $true;
        }

        It 'returns $true when DDC does not exist with mulitple DDCs.' {
            Mock -CommandName GetRegistryValue -MockWith { return 'ddc1 ddc2'; }
            Test-TargetResource -Name 'ddc3' -Ensure 'Absent' | Should Be $true;
        }

    } #end context ensure absent
    
} #end describe cXD7VDAController\Test-TargetResource