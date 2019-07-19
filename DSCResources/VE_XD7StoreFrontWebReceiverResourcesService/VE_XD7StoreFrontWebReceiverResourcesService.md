## XD7StoreFrontWebReceiverResourcesService

Set the WebReceiver Resources Service settings

### Syntax

```
XD7StoreFrontWebReceiverResourcesService [string]
{
    StoreName = [String]
    [ PersistentIconCacheEnabled = [Boolean] ]
    [ IcaFileCacheExpiry = [UInt32] ]
    [ IconSize = [UInt32] ]
    [ ShowDesktopViewer = [Boolean] ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **PersistentIconCacheEnabled**: Whether to cache icon data in the local file system.
* **IcaFileCacheExpiry**: How long the ICA file data is cached in the memory of the Web Proxy.
* **IconSize**: The desired icon size sent to the Store Service in icon requests.
* **ShowDesktopViewer**: Shows the Citrix Desktop Viewer window and toolbar when users access their desktops from legacy clients. This setting may fix problems where the Desktop Viewer is not displayed. Default: Off..

### Configuration

```
Configuration XD7Example {
    Import-DSCResource -ModuleName XenDesktop7 {
    XD7StoreFrontWebReceiverResourcesService XD7StoreFrontWebReceiverResourcesServiceExample {
        StoreName = 'mock'
        ShowDesktopViewer = $false
    }
}
```
