<# VE_XD7StoreFrontFarmConfiguration\VE_XD7StoreFrontFarmConfiguration.Resources.psd1 #>
ConvertFrom-StringData @'
    TrappedError                        = Trapped error getting store farm configuration. Error: '{0}'.
    CallingGetSTFStoreService           = Calling Get-STFStoreService for store '{0}'.
    CallingGetSTFStoreFarmConfiguration = Calling Get-STFStoreFarmConfiguration.
    SettingResourceProperty             = Setting resource property '{0}'.
    CallingSetSTFStoreFarmConfiguration = Calling Set-STFStoreFarmConfiguration
    ResourcePropertyMismatch            = Property '{0}' is NOT in desired state; expected '{1}', actual '{2}'.
    ResourceInDesiredState              = Citrix StoreFront farm configuration is in the desired state.
    ResourceNotInDesiredState           = Citrix StoreFront farm configuration is NOT in the desired state.
'@
