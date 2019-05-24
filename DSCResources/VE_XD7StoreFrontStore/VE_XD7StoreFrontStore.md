## XD7StoreFrontStore

Creates or sets a StoreFront store and all it's properties.

### Syntax

```
XD7StoreFrontStore [string]
{
    StoreName = [String]
    AuthType = [String] { Explicit | Anonymous }
    Servers = [String[]]
    FarmName = [String]
    [ Port = [UInt32] ]
    [ TransportType = [String] { HTTP | HTTPS | SSL } ]
    [ LoadBalance = [Boolean] ]
    [ FarmType = [String] { XenApp | XenDesktop | AppController } ]
    [ AuthVirtualPath = [String] ]
    [ StoreVirtualPath = [String] ]
    [ SiteId = [UInt64] ]
    [ ServiceUrls = [String[]] ]
    [ SSLRelayPort = [UInt32] ]
    [ AllFailedBypassDuration = [UInt32] ]
    [ BypassDuration = [UInt32] ]
    [ Zones = [String[]] ]
    [ LockedDown = [Boolean] ]
    [ Ensure = [String] { Present | Absent } ]
}
```

### Properties

* **StoreName**: Citrix StoreFront name.
* **AuthType**: Citrix StoreFront Authentication type.
* **FarmName**: Citrix StoreFront farm name.
* **Port**: Citrix StoreFront port.
* **TransportType**: Citrix StoreFront transport type.
* **Servers[]**: Citrix StoreFront delivery controllers.
* **LoadBalance**: Citrix StoreFront enable load balancing.
* **FarmType**: Citrix StoreFront farm type.
* **AuthVirtualPath**: Citrix StoreFront authenication service virtual path.
  * If not specified, this value defaults to /Citrix/<StoreName>auth.
* **StoreVirtualPath**: Citrix StoreFront store virtual path.
  * If not specified, this value defaults to /Citrix/<StoreName>.
* **SiteId**: Citrix StoreFront site id.
  * If not specified, this value defaults to 1.
* **ServiceUrls[]**: Citrix StoreFront service urls.
* **SSLRelayPort**: Citrix StoreFront ssl relay port.
* **AllFailedBypassDuration**: Citrix StoreFront all failed bypass duration.
* **BypassDuration**: Citrix StoreFront bypass duration.
* **Zones[]**: Citrix StoreFront zones.
* **LockedDown**: All the resources delivered by locked-down Store are auto subscribed and do not allow for un-subscription.
* **Ensure**: Ensure.

### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontStore XD7StoreFrontStoreExample {
        StoreName = 'mock'
        FarmName = 'mockfarm'
        Port = 8010
        TransportType = 'HTTP'
        Servers = "testserver01,testserver02"
        FarmType = 'XenDesktop'
        AuthType = 'Explicit'
        Ensure = 'Present'
    }
}
```
