function InvokeScriptBlock {
<#
    .SYNOPSIS
        Invokes a script block (required to Mock script block invocation calls in Pester).
    .NOTES
        This cannot live in the XD7Common module as the local variables are not available in its scope.
        This function is dot-sourced from calling modules where required.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Management.Automation.ScriptBlock] $ScriptBlock
    )
    process {

        return & $ScriptBlock;

    }
} #end function InvokeScriptBlock
