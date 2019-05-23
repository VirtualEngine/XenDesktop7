```
XD7StoreFrontPNA [string]
{
    StoreName = [String]
    [ DefaultPnaService = [Boolean] ]
    [ Ensure = [String] { Absent | Present } ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **DefaultPnaService**: Configure the Store to be the default PNA site hosted at http://example.storefront.com/Citrix/Store/PNAgent/config.xml.
* **Ensure**: Ensure.


### Configuration

```
Configuration XD7StoreFrontUnifiedExperienceExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontPNA XD7StoreFrontPNAExample {
       StoreName = 'mock'
       DefaultPnaService = $true
    }
}
```
