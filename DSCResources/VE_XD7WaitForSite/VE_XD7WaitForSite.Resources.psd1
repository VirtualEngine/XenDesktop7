<# VE_XD7WaitForSite\VE_XD7WaitForSite.psd1 #>
ConvertFrom-StringData @'
    XenDesktopSDKNotFoundError = The Citrix Powershell SDK/Snap-in was not found.
    TestingXDSite              = Testing for Citrix XenDesktop 7.x '{0}' site availability on controller '{1}'.
    XDSiteNotFoundRetrying     = Citrix XenDesktop 7.x site '{0}' not found. Will retry again after {1} seconds.
    XDSiteNotFoundTimeout      = Citrix XenDesktop 7.x site '{0}' not found after {1} attempts.
    ResourceInDesiredState     = Citrix XenDesktop 7.x site '{0}' is in the desired state.
    ResourceNotInDesiredState  = Citrix XenDesktop 7.x site '{0}' is NOT in the desired state.
    InvokingScriptBlock        = Invoking script block...
'@
