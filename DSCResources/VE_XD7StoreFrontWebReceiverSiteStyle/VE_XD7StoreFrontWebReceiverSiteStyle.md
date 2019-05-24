## XD7StoreFrontWebReceiverSiteStyle

Sets the Style info in the custom style sheet

### Syntax

```
XD7StoreFrontWebReceiverSiteStyle [string]
{
    StoreName = [String]
    [ HeaderLogoPath = [String] ]
    [ LogonLogoPath = [String] ]
    [ HeaderBackgroundColor = [String] ]
    [ HeaderForegroundColor = [String] ]
    [ LinkColor = [String] ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **HeaderLogoPath**: Header logo path. This file must exist and it cannot be in the ..\receiver\images folder or subfolders. Preferably the custom folder.
* **LogonLogoPath**: Logon logo path. This file must exist and it cannot be in the ..\receiver\images folder or subfolders. Preferably the custom folder.
* **HeaderBackgroundColor**: Background color of the Header.
* **HeaderForegroundColor**: Foreground color of the Header.
* **LinkColor**: Link color of the page.

### Configuration

```
Configuration XD7Example {
    Import-DSCResource -ModuleName XenDesktop7 {
    XD7StoreFrontWebReceiverSiteStyle XD7StoreFrontWebReceiverSiteStyleExample {
       StoreName = 'mock'
       LinkColor = '#02a1c1'
       HeaderBackgroundColor = '#0574f5b'
       HeaderForegroundColor = '#fff'
       HeaderLogoPath = 'C:\inetpub\wwwroot\Citrix\mockweb\custom\CustomHeader.png'
       LogonLogoPath = 'C:\inetpub\wwwroot\Citrix\mockweb\custom\CustomLogon.png'
    }
}
```
