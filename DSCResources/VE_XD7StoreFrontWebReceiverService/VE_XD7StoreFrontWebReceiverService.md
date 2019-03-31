
## XD7StoreFrontWebReceiverService

Configure Receiver for Web service options

### Syntax

```
XD7StoreFrontWebReceiverService [string]
{
    StoreName = [String]
    VirtualPath = [String]
    SiteId = [UInt64]
    [ ClassicReceiverExperience = [Boolean] ]
    [ FriendlyName = [String] ]
    [ Ensure = [String] { Present | Absent } ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **VirtualPath**: Site virtual path.
* **SiteId**: IIS site id.
  * If not specified, this value defaults to 1.
* **ClassicReceiverExperience**: Enable the classic Receiver experience.
* **FriendlyName**: Friendly name to identify the Receiver for Web service.
* **Ensure**: Whether the Storefront Web Receiver Service should be added or removed.

### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontWebReceiverService XD7StoreFrontWebReceiverServiceExample {
        StoreName = 'mock'
        VirtualPath = '/Citrix/mockweb'
        ClassicReceiverExperience = $false
        Ensure = 'Present'
    }
}
```
