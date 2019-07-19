## XD7StoreFrontStoreFarm

Set the details of a StoreFront farm

### Syntax

```
XD7StoreFrontStoreFarm [string]
{
    StoreName = [String]
    FarmName = [String]
    [ FarmType = [String] { XenApp | XenDesktop | AppController | VDIinaBox | Store } ]
    [ Servers = [String[]] ]
    [ ServiceUrls = [String[]] ]
    [ Port = [UInt32] ]
    [ TransportType = [String] { HTTP | HTTPS | SSL } ]
    [ SSLRelayPort = [UInt32] ]
    [ LoadBalance = [Boolean] ]
    [ AllFailedBypassDuration = [UInt32] ]
    [ BypassDuration = [UInt32] ]
    [ TicketTimeToLive = [UInt32] ]
    [ RadeTicketTimeToLive = [UInt32] ]
    [ MaxFailedServersPerRequest = [UInt32] ]
    [ Zones = [String[]] ]
    [ Product = [String] ]
    [ RestrictPoPs = [String] ]
    [ FarmGuid = [String] ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **FarmName**: The name of the Farm.
* **FarmType**: The type of farm.
* **Servers**: The hostnames or IP addresses of the xml services.
* **ServiceUrls**: The url to the service location used to provide web and SaaS apps via this farm.
* **Port**: Service communication port.
* **TransportType**: Type of transport to use. Http, Https, SSL for example.
* **SSLRelayPort**: The SSL Relay port.
* **LoadBalance**: Round robin load balance the xml service servers.
* **AllFailedBypassDuration**: Period of time to skip all xml service requests should all servers fail to respond.
* **BypassDuration**: Period of time to skip a server when is fails to respond.
* **TicketTimeToLive**: Period of time an ICA launch ticket is valid once requested on pre 7.0 XenApp and XenDesktop farms.
* **RadeTicketTimeToLive**: Period of time a RADE launch ticket is valid once requested on pre 7.0 XenApp and XenDesktop farms.
* **MaxFailedServersPerRequest**: Maximum number of servers within a single farm that can fail before aborting a request.
* **Zones**: The list of Zone names associated with the Store Farm.
* **Product**: Cloud deployments only otherwise ignored. The product name of the farm configured.
* **RestrictPoPs**: Cloud deployments only otherwise ignored. Restricts GWaaS traffic to the specified POP.
* **FarmGuid**: Cloud deployments only otherwise ignored. A tag indicating the scope of the farm.

### Configuration

```
Configuration XD7Example {
    Import-DSCResource -ModuleName XenDesktop7 {
    XD7StoreFrontStoreFarm XD7StoreFrontStoreFarmExample {
       StoreName = 'mock'
       FarmName = 'farm2'
       Servers = 'Server10','Server11'
       FarmType = 'XenApp'
       TransportType = 'HTTPS'
    }
}
```
