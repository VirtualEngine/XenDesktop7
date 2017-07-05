<#
    Wrapper for loading the Citrix.DelegatedAdmin.Admin.V1 snpain as a module that can be loaded at
    the global scope. This avoids 'An item with the same key has already been added' errors when
    loading PowerShell snap-ins with the PsDscRunAsCredential parameter in PowerShell v5 (and
    later).
#>

$snapinName = 'Citrix.DelegatedAdmin.Admin.V1';
if ($null -eq (Get-PSSnapin -Name $snapinName -ErrorAction SilentlyContinue))  {

    Add-PSSnapin -Name $snapinName -ErrorAction Stop;

}
