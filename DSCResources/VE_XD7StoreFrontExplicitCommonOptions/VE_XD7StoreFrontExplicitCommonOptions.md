
## XD7StoreFrontExplicitCommonOptions

Set the ExplicitCommon protocol options

### Syntax

```
XD7StoreFrontExplicitCommonOptions [string]
{
    StoreName = [String]
    [ Domains[] = [String] ]
    [ DefaultDomain = [String] ]
    [ HideDomainField = [Boolean] ]
    [ AllowUserPasswordChange = [String] { Always | ExpiredOnly | Never } ]
    [ ShowPasswordExpiryWarning = [String] { Custom | Never | Windows } ]
    [ PasswordExpiryWarningPeriod = [Uint32] ]
    [ AllowZeroLengthPassword = [Boolean] ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **Domains[]**: List of trusted domains.
* **DefaultDomain**: The default domain to use when omitted during login.
* **HideDomainField**: Hide the domain field on the login form.
* **AllowUserPasswordChange**: Configure when a user can change a password.
* **ShowPasswordExpiryWarning**: Show the password expiry warning to the user.
* **PasswordExpiryWarningPeriod**: The period of time in days before the expiry warning should be shown.
* **AllowZeroLengthPassword**: Allow a zero length password.


### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontExplicitCommonOptions XD7Example {
        StoreName = 'mock'
        Domains = 'ipdev'
        DefaultDomain = 'ipdev'
        AllowUserPasswordChange = 'Always'
    }
}
```
