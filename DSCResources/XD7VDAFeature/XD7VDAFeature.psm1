$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
## Dot source XD7Common functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Get-ChildItem -Path "$moduleParent\XD7Common" -Include *.ps1 -Exclude '*.Tests.ps1' -Recurse |
    ForEach-Object {
        Write-Verbose ('Dot sourcing ''{0}''.' -f $_.FullName);
        . $_.FullName;
    }

## Dot source all (nested) .ps1 files in the folder, excluding Pester tests
Get-ChildItem -Path $moduleRoot -Include *.ps1 -Exclude '*.Tests.ps1' -Recurse |
    ForEach-Object {
        Write-Verbose ('Dot sourcing ''{0}''.' -f $_.FullName);
        . $_.FullName;
    }

Export-ModuleMember -Function *-TargetResource;
