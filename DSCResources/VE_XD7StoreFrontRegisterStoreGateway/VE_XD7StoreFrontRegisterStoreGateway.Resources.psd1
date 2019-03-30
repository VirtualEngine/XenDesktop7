<# VE_XD7StoreFrontRegisterStoreGateway\VE_XD7StoreFrontRegisterStoreGateway.Resources.psd1 #>
ConvertFrom-StringData @'
    CallingGetSTFStoreService          = Calling Get-STFStoreService for store '{0}'.
    CallingGetSTFAuthenticationService = Calling Get-STFAuthenticationService.
    CallingGetSTFRoamingGateway        = Calling Get-STFRoamingGateway for gateway '{0}'.
    CallingRegisterSTFStoreGateway     = Calling Register-STFStoreGateway.
    CallingUnegisterSTFStoreGateway    = Calling Unregister-STFStoreGateway.
    ProtocolEnabled                    = Gateway protocol '{0}' enabled.
    EnablingProtocol                   = Enabling gateway protocol '{0}'.
    DisablingProtocol                  = Disabling gateway protocol '{0}'.
    ProtocolDisabled                   = Gateway protocol '{0}' disabled.
    ResourcePropertyMismatch           = Property '{0}' is NOT in desired state; expected '{1}', actual '{2}'.
    ResourceInDesiredState             = Citrix StoreFront Registered Gateway is in the desired state.
    ResourceNotInDesiredState          = Citrix StoreFront Registered Gateway is NOT in the desired state.
'@
