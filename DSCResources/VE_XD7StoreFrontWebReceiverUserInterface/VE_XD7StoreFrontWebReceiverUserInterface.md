```
XD7StoreFrontWebReceiverUserInterface [string]
{
    StoreName = [String]
    [ AutoLaunchDesktop = [Boolean] ]
    [ MultiClickTimeout = [UInt32] ]
    [ EnableAppsFolderView = [Boolean] ]
    [ ShowAppsView = [Boolean] ]
    [ ShowDesktopsView = [Boolean] ]
    [ DefaultView = [String] { Apps | Auto | Desktops } ]
    [ WorkspaceControlEnabled = [Boolean] ]
    [ WorkspaceControlAutoReconnectAtLogon = [Boolean] ]
    [ WorkspaceControlLogoffAction = [String] { Disconnect | None | Terminate } ]
    [ WorkspaceControlShowReconnectButton = [Boolean] ]
    [ WorkspaceControlShowDisconnectButton = [Boolean] ]
    [ ReceiverConfigurationEnabled = [Boolean] ]
    [ AppShortcutsEnabled = [Boolean] ]
    [ AppShortcutsAllowSessionReconnect = [Boolean] ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **AutoLaunchDesktop**: Whether to auto-launch desktop at login if there is only one desktop available for the user.
* **MultiClickTimeout**: The time period for which the spinner control is displayed, after the user clicks on the App or Desktop icon within Receiver for Web.
* **EnableAppsFolderView**: Allows the user to turn off folder view when in a locked-down store or unauthenticated store.
* **ShowAppsView**: Whether to show the apps view tab.
* **ShowDesktopsView**: Whether to show the desktops tab.
* **DefaultView**: The view to show after logon.
* **WorkspaceControlEnabled**: Whether to enable workspace control.
* **WorkspaceControlAutoReconnectAtLogon**: Whether to perform auto-reconnect at login.
* **WorkspaceControlLogoffAction**: Whether to disconnect or terminate HDX sessions when actively logging off Receiver for Web.
* **WorkspaceControlShowReconnectButton**: Whether to show the reconnect button or link.
* **WorkspaceControlShowDisconnectButton**: Whether to show the disconnect button or link.
* **ReceiverConfigurationEnabled**: Enable the Receiver Configuration .CR download file.
* **AppShortcutsEnabled**: Enable App Shortcuts.
* **AppShortcutsAllowSessionReconnect**: Enable App Shortcuts to support session reconnect.


### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontWebReceiverUserInterface XD7Example {
        StoreName = 'mock'
        WorkspaceControlLogoffAction = 'Disconnect'
        WorkspaceControlEnabled = $True
        WorkspaceControlAutoReconnectAtLogon = $True
        AutoLaunchDesktop = $True
        ShowDesktopsView = $False
        ReceiverConfigurationEnabled = $False
        MultiClickTimeout = 3
        DefaultView = 'Apps'
    }
}
```