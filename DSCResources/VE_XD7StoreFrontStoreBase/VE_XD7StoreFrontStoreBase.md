## VE_XD7StoreFrontStoreBase

Creates or sets a StoreFront store.

### Syntax

```
VE_XD7StoreFrontStoreBase [string]
{
    StoreName = [String]
    AuthType = [String] { Explicit | Anonymous }
    [ AuthVirtualPath = [String] ]
    [ StoreVirtualPath = [String] ]
    [ SiteId = [UInt64] ]
    [ LockedDown = [Boolean] ]
    [ Ensure = [String] { Present | Absent } ]
}
```

### Properties

* **StoreName**: Citrix StoreFront name.
* **AuthType**: Citrix StoreFront Authentication type.
* **AuthVirtualPath**: Citrix StoreFront authenication service virtual path.
  * If not specified, this value defaults to /Citrix/Authentication.
* **StoreVirtualPath**: Citrix StoreFront store virtual path.
  * If not specified, this value defaults to /Citrix/<StoreName>.
* **SiteId**: Citrix StoreFront site id.
  * If not specified, this value defaults to 1.
* **LockedDown**: All the resources delivered by locked-down Store are auto subscribed and do not allow for un-subscription.
* **Ensure**: Specifies whether the Store should be present or absent.
  * If not specified, this value defaults to 'Present'.

### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    VE_XD7StoreFrontStoreBase VE_XD7StoreFrontStoreBaseExample {
        StoreName = 'Store'
        AuthType = 'Explicit'
        StoreVirtualPath = '/Citrix/Store'
        AuthVirtualPath = '/Citrix/Authentication'
        Ensure = 'Present'
    }
}
```
