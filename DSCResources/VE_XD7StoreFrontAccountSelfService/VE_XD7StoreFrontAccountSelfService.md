```
XD7StoreFrontAccountSelfService [string]
{
    StoreName = [String]
    [ AllowResetPassword = [Boolean] ]
    [ AllowUnlockAccount = [Boolean] ]
    [ PasswordManagerServiceUrl = [String] ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **AllowResetPassword**: Allow self-service reset password.
* **AllowUnlockAccount**: Allow self-service account unlock.
* **PasswordManagerServiceUrl**: The Url of the password manager account self-service service. This must end with a /. Set to $null to remove.


### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontAccountSelfService XD7StoreFrontAccountSelfServiceExample {
        StoreName = 'mock'
        AllowResetPassword = $true
        AllowUnlockAccount = $true
        PasswordManagerServiceUrl = 'http://WebServer/url/'
    }
```
