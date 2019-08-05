## XD7StoreFrontRoamingGateway

Add or update a Gateway that can be used for remote access and authentication.

### Syntax

```
XD7StoreFrontRoamingGateway [string]
{
    Name = [String]
    LogonType = [String] { UsedForHDXOnly | Domain | RSA | DomainAndRSA | SMS | GatewayKnows | SmartCard | None }
    GatewayUrl = [String]
    [ SmartCardFallbackLogonType = [String] ]
    [ Version = [String] ]
    [ CallbackUrl = [String] ]
    [ SessionReliability = [Boolean] ]
    [ RequestTicketTwoSTAs = [Boolean] ]
    [ SubnetIPAddress = [String] ]
    [ SecureTicketAuthorityUrls = [String[]] ]
    [ StasUseLoadBalancing = [Boolean] ]
    [ StasBypassDuration = [String] ]
    [ GslbUrl = [String] ]
    [ Ensure = [String] { Present | Absent } ]
}
```

### Properties

* **Name**: Gateway friendly name.
* **LogonType**: The login type required and supported by the Gateway.
* **SmartCardFallbackLogonType**: The login type to use when SmartCard fails.
* **Version**: The Citrix NetScaler Gateway version.
* **GatewayUrl**: The Gateway Url.
* **CallbackUrl**: The Gateway authentication call-back Url.
  * _NOTE: The CallbackUrl should be suffixed with `/CitrixAuthService/AuthService.asmx`_
* **SessionReliability**: Enable session reliability.
* **RequestTicketTwoSTAs**: Request STA tickets from two STA servers.
* **SubnetIPAddress**: IP address.
* **SecureTicketAuthorityUrls[]**: Secure Ticket Authority server Urls.
* **StasUseLoadBalancing**: Load balance between the configured STA servers.
* **StasBypassDuration**: Time before retrying a failed STA server.
* **GslbUrl**: GSLB domain used by multiple gateways.
* **Ensure**: Ensure.


### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontRoamingGateway XD7StoreFrontRoamingGatewayExample {
        Name = 'Netscaler'
        LogonType = 'Domain'
        GatewayUrl = 'https://accessgateway/netscaler'
        Version = 'Version10_0_69_4'
        SecureTicketAuthorityUrls = 'https://staurl/scripts/ctxsta.dll'
        SessionReliability = $true
        Ensure = 'Present'
    }
}
```
