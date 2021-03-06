
## XD7StoreFrontOptimalGateway

Set the farms and the optimal gateway to use for launch.

### Syntax

```
XD7StoreFrontOptimalGateway [string]
{
    GatewayName = [String]
    ResourcesVirtualPath = [String]
    Hostnames = [String[]]
    StaUrls = [String[]]
    [ Farms = [String[]] ]
    [ SiteId = [UInt64] ]
    [ StasUseLoadBalancing = [Boolean] ]
    [ StasBypassDuration = [String] ]
    [ EnableSessionReliability = [Boolean] ]
    [ UseTwoTickets = [Boolean] ]
    [ Zones = [String[]] ]
    [ EnabledOnDirectAccess = [Boolean] ]
    [ Ensure = [String] { Present | Absent } ]
}
```

### Properties

* **GatewayName**: StoreFront gateway name.
* **SiteId**: Site Id.
  * If not specified, this value defaults to 1.
* **ResourcesVirtualPath**: Resources Virtual Path.
* **Hostnames[]**: Hostnames.
* **StaUrls[]**: Secure Ticket Authority server Urls.
* **StasUseLoadBalancing**: Load balance between the configured STA servers.
* **StasBypassDuration**: Time before retrying a failed STA server.
* **EnableSessionReliability**: Enable session reliability.
* **UseTwoTickets**: Request STA tickets from two STA servers.
* **Farms[]**: Farms.
* **Zones[]**: Zones.
  * If not specified, it will be set to all farms.
* **EnabledOnDirectAccess**: Enabled On Direct Access.
* **Ensure**: Ensure.

### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontOptimalGateway XD7StoreFrontOptimalGatewayExample {
        ResourcesVirtualPath = '/Citrix/mock'
        GatewayName = 'ag.netscaler.com'
        Hostnames = @('ag.netscaler.com:443','ag2.netscaler.com:443')
        StaUrls = @('http://test/Scripts/CtxSTA.dll','http://test2/Scripts/CtxSTA.dll')
        StasBypassDuration = '02:00:00'
        Ensure = 'Present'
    }
}
```
