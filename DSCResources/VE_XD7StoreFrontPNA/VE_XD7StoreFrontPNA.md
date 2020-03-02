```
XD7StoreFrontPNA [string]
{
    StoreName = [String]
    [ DefaultPnaService = [Boolean] ]
    [ LogonMode = [String] { Anonymous | Prompt | SSON | Smartcard_SSON | Smartcard_Prompt } ]
    [ Ensure = [String] { Absent | Present } ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **DefaultPnaService**: Configure the Store to be the default PNA site hosted at http://example.storefront.com/Citrix/Store/PNAgent/config.xml.
* **LogonMode**: The PNA logon method.  Defaults to Prompt.
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
