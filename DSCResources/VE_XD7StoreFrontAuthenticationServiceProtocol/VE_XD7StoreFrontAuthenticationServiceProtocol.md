## XD7StoreFrontAuthenticationServiceProtocol

Enables or disables StoreFront authentication service protocol(s).

**NOTE: this is a replacement for the `XD7StoreFrontAuthenticationMethod` resource implemented using the new StoreFront 3.x PowerShell cmdlets.**

### Syntax

```
XD7StoreFrontAuthenticationServiceProtocol [string]
{
    VirtualPath = [String]
    AuthenticationProtocol[] = [String] { CitrixAGBasic | CitrixAGBasicNoPassword | HttpBasic | Certificate | CitrixFederation | IntegratedWindows | Forms-Saml | ExplicitForms }
    [ SiteId = [Uint64] ]
    [ Ensure = [String] { Present | Absent } ]
}
```

### Properties

* **VirtualPath**: Citrix Storefront Authentication Service IIS virtual path.
* **AuthenticationProtocol**: Citrix Storefront Authentication protocols to enable or disable.
* **SiteId**: Citrix Storefront Authentication Service IIS Site Id.
  * If not specified, this value defaults to 1.
* **Ensure**: Specifies whether to enable or disable the authentication protocol(s).
  * If not specified, this value defaults to 'Present'.

### Configuration

```
Configuration XD7Example {
    Import-DSCResource -ModuleName XenDesktop7 {
    XD7StoreFrontAuthenticationServiceProtocol AuthenticationServiceProtocolExample {
       VirtualPath = '/Citrix/Authentication'
       AuthenticationProtocol= 'ExplicitForms','IntegratedWindows','CitrixAGBasic'
       Ensure = 'Present'
    }
}
```
