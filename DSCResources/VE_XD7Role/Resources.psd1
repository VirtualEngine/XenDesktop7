<# XD7Role\Resources.psd1 #>
ConvertFrom-StringData @'
    XenDesktopSDKNotFoundError = Citrix XenDesktop 7.x Powershell SDK/Snap-in was not found.
    UserNameNotFullyQualifiedWarning = The Citrix XenDesktop 7.x administrator reference '{0}' is not fully qualified. Specify the administrator's Domain\\UserName or Domain\\GroupName to avoid any ambiguity.
    MissingRoleMember = Citrix XenDesktop 7.x account/group '{0}' is missing and will be added.
    SurplusRoleMember = Citrix XenDesktop 7.x account/group '{0}' is surplus and will be removed.
    AddingRoleMember = Adding Citrix XenDesktop 7.x Administrator '{0}' to role '{1}'.
    RemovingRoleMember = Removing Citrix XenDesktop 7.x Administrator '{0}' from role '{1}'.
    ResourceInDesiredState = Citrix XenDesktop 7.x Role '{0}' is in the desired state.
    ResourceNotInDesiredState = Citrix XenDesktop 7.x Role '{0}' is NOT in the desired state.
    InvokingScriptBlockWithParams = Invoking script block with parameters: '{0}'.
'@
