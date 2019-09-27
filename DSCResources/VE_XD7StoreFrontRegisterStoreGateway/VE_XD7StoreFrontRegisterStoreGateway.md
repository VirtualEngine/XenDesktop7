## XD7StoreFrontRegisterStoreGateway

Register an authentication Gateway with a Store.

### Syntax

```
XD7StoreFrontRegisterStoreGateway [string]
{
    StoreName = [String]
    GatewayName = [String[]]
    EnableRemoteAccess = [Boolean]
    [ Ensure = [String] { Present | Absent } ]
}
```

### Properties

* **StoreName**: Citrix StoreFront name.
* **GatewayName[]**: Gateway name.
* **EnableRemoteAccess**: Enable Remote Access.
* **Ensure**: Ensure.

### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontRegisterStoreGateway XD7StoreFrontRegisterStoreGatewayExample {
        GatewayName = 'Netscaler'
        StoreName = 'mock'
        EnableRemoteAccess = $True
        Ensure = 'Present'
    }
}
```
