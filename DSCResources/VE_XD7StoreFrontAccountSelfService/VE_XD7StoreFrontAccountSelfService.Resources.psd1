<# VE_XD7StoreFrontAccountSelfService\VE_XD7StoreFrontAccountSelfService.Resources.psd1 #>
ConvertFrom-StringData @'
    TrappedError              = Trapped error getting account self service. Error: '{0}'.
    CallingGetSTFStoreService = Calling Get-STFStoreService for store '{0}'.
    CallingGetSTFAccountSelfService = Calling Get-STFAccountSelfService.
    CallingGetSTFAuthenticationService = Calling Get-STFAuthenticationService for virtualpath '{0}' and siteid '{1}'
    CallingGetSTFPasswordManagerAccountSelfService = Calling Get-STFPasswordManagerAccountSelfService.
    SettingResourceProperty           = Setting resource property '{0}'.
    CallingSetSTFAccountSelfService = Calling Set-STFAccountSelfService.
    CallingSetSTFPasswordManagerAccountSelfService = Calling Set-STFPasswordManagerAccountSelfService.
    ResourcePropertyMismatch      = Property '{0}' is NOT in desired state; expected '{1}', actual '{2}'.
    ResourceInDesiredState        = Citrix StoreFront account self service is in the desired state.
    ResourceNotInDesiredState     = Citrix StoreFront account self service is NOT in the desired state.
'@
