<# XD7CatalogMachine\Resources.psd1 #>
ConvertFrom-StringData @'
    XenDesktopSDKNotFoundError = The Citrix Powershell SDK/Snap-in was not found.
    InvokingScriptBlockWithParams = Invoking script block with parameters: '{0}'.
    AddingMachineCatalogMachine = Adding machine '{0}' to Citrix XenDesktop 7.x Machine Catalog '{1}'.
    RemovingMachineCatalogMachine = Removing machine '{0}' from Citrix XenDesktop 7.x Machine Catalog '{1}'.
    ResourcePropertyMismatch = Property '{0}' is NOT in desired state; expected '{1}', actual '{2}'.
    ResourceInDesiredState = Citrix XenDesktop 7.x Machine Catalog machine(s) '{0}' is in the desired state.
    ResourceNotInDesiredState = Citrix XenDesktop 7.x Machine Catalog machine(s) '{0}' is NOT in the desired state.
'@