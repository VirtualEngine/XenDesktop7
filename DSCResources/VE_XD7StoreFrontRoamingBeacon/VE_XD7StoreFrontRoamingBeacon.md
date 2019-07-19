## XD7StoreFrontRoamingBeacon

Set the internal and external beacons

### Syntax

```
XD7StoreFrontRoamingBeacon [string]
{
    SiteId = [UInt64]
    [ InternalUri = [String] ]
    [ ExternalUri = [String[]] ]
}
```

### Properties

* **SiteId**: Site Id.
* **InternalUri**: Beacon internal address uri. You can set this one by itself.
* **ExternalUri**: Beacon external address uri. If you specify externaluri, you must also include internaluri.


### Configuration

```
Configuration XD7Example {
    Import-DSCResource -ModuleName XenDesktop7 {
    XD7StoreFrontRoamingBeacon XD7StoreFrontStoreFarmExample {
       SiteId = 1
       InternalURI = 'http://localhost/'
       ExternalURI = 'http://web.client1.com','http://web.client2.com'
    }
}
```
