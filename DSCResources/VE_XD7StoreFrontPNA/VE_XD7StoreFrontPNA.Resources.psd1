<# VE_XD7StoreFrontPNA\VE_XD7StoreFrontPNA.Resources.psd1 #>
ConvertFrom-StringData @'
    TrappedError              = Trapped error getting roaming beacon. Error: '{0}'.
    CallingGetSTFStoreService = Calling Get-STFStoreService for store '{0}'.
    CallingGetSTFStorePna = Calling Get-STFStorePna.
    CallingEnableSTFStorePna = Calling Enable-STFStorePna.
    SettingResourceProperty           = Setting resource property '{0}'.
    CallingDisableSTFStorePna = Calling Disable-STFStorePna.
    ResourcePropertyMismatch      = Property '{0}' is NOT in desired state; expected '{1}', actual '{2}'.
    ResourceInDesiredState        = Citrix StoreFront PNA is in the desired state.
    ResourceNotInDesiredState     = Citrix StoreFront PNA is NOT in the desired state.
'@
