#requires -Version 4
#requires -Modules PSScriptAnalyzer

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path;
Describe 'Linting\PSScriptAnalyzer' {

    Get-ChildItem -Path "$repoRoot\DSCResources" -Recurse -File | ForEach-Object {
        It "File '$($_.Name)' passes PSScriptAnalyzer rules" {
            $invokeScriptAnalyzerParams = @{
                Path        = $_.FullName
                Severity    = 'Warning'
                ExcludeRule = 'PSReviewUnusedParameter'
            }
            $result = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParams | Select-Object -ExpandProperty Message
            $result | Should BeNullOrEmpty
        }
    }
}
