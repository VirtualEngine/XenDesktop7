## XD7StoreFrontWebReceiverPluginAssistant

Set the WebReceiver Plug-in Assistant options.

### Syntax

```
XD7StoreFrontWebReceiverPluginAssistant [string]
{
    StoreName = [String]
    [ Enabled = [Boolean] ]
    [ UpgradeAtLogin = [Boolean] ]
    [ ShowAfterLogin = [Boolean] ]
    [ Win32Path = [String] ]
    [ MacOSPath = [String] ]
    [ MacOSMinimumSupportedVersion = [String] ]
    [ Html5Enabled = [String] { Always | Fallback | Off } ]
    [ Html5Platforms = [String] ]
    [ Html5Preferences = [String] ]
    [ Html5SingleTabLaunch = [Boolean] ]
    [ Html5ChromeAppOrigins = [String] ]
    [ Html5ChromeAppPreferences = [String] ]
    [ ProtocolHandlerEnabled = [Boolean] ]
    [ ProtocolHandlerPlatforms = [String] ]
    [ ProtocolHandlerSkipDoubleHopCheckWhenDisabled = [Boolean] ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **Enabled**: Enable Receiver client detection.
* **UpgradeAtLogin**: Prompt to upgrade older clients.
* **ShowAfterLogin**: Show Receiver client detection after the user logs in.
* **Win32Path**: Path to the Windows Receiver.
* **MacOSPath**: Path to the MacOS Receiver.
* **MacOSMinimumSupportedVersion**: Minimum version of the MacOS supported.
* **Html5Enabled**: Method of deploying and using the Html5 Receiver.
* **Html5Platforms**: The supported Html5 platforms.
* **Html5Preferences**: Html5 Receiver preferences.
* **Html5SingleTabLaunch**: Launch Html5 Receiver in the same browser tab.
* **Html5ChromeAppOrigins**: The Html5 Chrome Application Origins settings.
* **Html5ChromeAppPreferences**: The Html5 Chrome Application preferences.
* **ProtocolHandlerEnabled**: Enable the Receiver Protocol Handler.
* **ProtocolHandlerPlatforms**: The supported Protocol Handler platforms.
* **ProtocolHandlerSkipDoubleHopCheckWhenDisabled**: Skip the Protocol Handle double hop check.

### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontWebReceiverPluginAssistant XD7StoreFrontWebReceiverPluginAssistantExample {
        StoreName = 'mock'
        Enabled = $false
    }
}
```
