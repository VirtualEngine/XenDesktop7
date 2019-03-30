<# VE_XD7StoreFrontSessionStateTimeout\VE_XD7StoreFrontSessionStateTimeout.Resources.psd1 #>
ConvertFrom-StringData @'
    TrappedError                    = Trapped error getting web receivers summary. Error: '{0}'.
    CallingGetSTFStoreService       = Calling Get-STFStoreService for store '{0}'.
    CallingGetSTFWebReceiverService = Calling Get-STFWebReceiverService.
    CallingGetDSWebReceiversSummary = Calling Get-DSWebReceiversSummary.
    CallingSetDSSessionStateTimeout = Calling Set-DSSessionStateTimeout.
    SettingResourceProperty         = Setting resource property '{0}'.
    ResourcePropertyMismatch        = Property '{0}' is NOT in desired state; expected '{1}', actual '{2}'.
    ResourceInDesiredState          = Citrix StoreFront WebReceiver session state timeout settings are in the desired state.
    ResourceNotInDesiredState       = Citrix StoreFront WebReceiver session state timeout settings are NOT in the desired state.
'@
