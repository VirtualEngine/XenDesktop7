<# VE_XD7StoreFrontRoamingBeacon\VE_XD7StoreFrontRoamingBeacon.Resources.psd1 #>
ConvertFrom-StringData @'
    TrappedError               = Trapped error getting roaming beacon. Error: '{0}'.
    CallingGetSTFRoamingBeacon = Calling Get-STFRoamingBeacon.
    SettingResourceProperty    = Setting resource property '{0}'.
    CallingSetSTFRoamingBeacon = Calling Set-STFRoamingBeacon -'{0}'.
    ResourcePropertyMismatch   = Property '{0}' is NOT in desired state; expected '{1}', actual '{2}'.
    ResourceInDesiredState     = Citrix StoreFront roaming beacon is in the desired state.
    ResourceNotInDesiredState  = Citrix StoreFront roaming beacon is NOT in the desired state.
'@
