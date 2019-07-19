## XD7StoreFrontAuthenticationService

Add or Remove a new Authentication service for Store and Receiver for Web authentication

### Syntax

```
XD7StoreFrontAuthenticationService [string]
{
    VirtualPath = [String]
    [ FriendlyName = [String] ]
    [ SiteId = [UInt64] ]
    [ Ensure = [String] { Present | Absent } ]
}
```

### Properties

* **VirtualPath**: The IIS virtual path to use for the service.
* **FriendlyName**: The friendly name the service should be known as.
* **SiteId**: The IIS site to configure the Authentication service for.
* **Ensure**: Ensure.

### Configuration

```
Configuration XD7Example {
    Import-DSCResource -ModuleName XenDesktop7 {
    XD7StoreFrontAuthenticationService XD7StoreFrontAuthenticationServiceExample {
        VirtualPath = '/Citrix/mockweb'
        FriendlyName = 'mockauth'
        SiteId = 1
    }
}
```
