Included Resources
==================
* XD7AccessPolicy
* XD7Administrator
* XD7Catalog
* XD7CatalogMachine
* XD7Controller
* XD7Database
* XD7DesktopGroup
* XD7DesktopGroupMember
* XD7DesktopGroupApplication
* XD7EntitlementPolicy
* XD7Feature
* XD7Role
* XD7Site
* XD7SiteLicense
* XD7VDAController
* XD7VDAFeature
* XD7WaitForSite

XD7AccessPolicy
===========
An access policy rule defines a set of connection filters and access control rights relating to a
desktop group.
###Syntax
```
XD7AccessPolicy [string]
{
    DeliveryGroup = [string]
    AccessType = [string] { AccessGateway | Direct }
    [Enabled = [bool]]
    [AllowRestart = [bool]]
    [Name = [string]]
    [Description = [string]]
    [Protocol = [string[]] { HDX | RDP }
    [IncludeUsers = [string[]]
    [ExcludeUsers = [string[]]
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **DeliveryGroup**: The Citrix XenDesktop 7.x delivery group name to assign the access policy.
* **AccessType**: The access policy filter type.
* **Enabled**: Whether the access policy is enabled. If not specified, it defaults to True.
* **AllowRestart**: Whether users are permitted to restart desktop group machines. If not specified, it defaults to True.
* **Name**: Name of the access policy. If not specified, it defaults to DesktopGroup_Direct or DesktopGroup_AG.
* **Description**: Custom description assigned to the access policy rule.
* **Protocol**: Permitted protocols. If not specified, it defaults to both HDX and RDP.
* **IncludeUsers**: List of associated Active Directory user and groups assigned to the access policy.
* **ExcludeUsers**: List of associated Active Directory user and groups excluded from the access policy.
* **Ensure**: Whether the role is to be installed or not. Supported values are Present or Absent. If not specified, it defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to access the source media and/or install/uninstall the specified role. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7AccessPolicyExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7AccessPolicy XD7AccessPolicyExample {
        DeliveryGroup = 'My Desktop Group'
        AccessType = 'AccessGateway'
        Enabled = $true
        AllowRestart = $true
        Protocol = 'HDX'
        IncludeUsers = @('DOMAIN\GroupA','DOMAIN\GroupB')
        Ensure = 'Present'
    }
}
```

XD7Administrator
================
Registers an administrator in Citrix XenDesktop site. Administrators needs to be registered
before they can be assigned to a role.

###Syntax
```
XD7Administrator [string]
{
    Name = [string]
    Enabled = [bool]
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **Name**: Active Direcrtory user/group name to register in the site database.
* **Enabled**: Defines whether the user/group is enabled. If not specified, it defaults to True.
* **Ensure**: Whether the administrator is present or not. Supported values are Present or Absent. If not specified, it defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to access the Citrix XenDesktop 7 site. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7AdministratorExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7Administrator XD7AdministratorExample {
        Name = 'Domain Admins'
        Enabled = $true
        Ensure = 'Present'
    }
}
```
XD7Catalog
==========
Creates a Citrix XenDesktop machine catalog.

###Syntax
```
XD7Catalog [string]
{
    Name = [string]
    [Description = [string]]
    Allocation = [string] { Permanent | Random | Static }
    Provisioning = [string] { Manual | PVS | MCS }
    Persistence = [string] { Discard | Local | PVD }
    [IsMultiSession = [bool]]
    [PvsAddress = [stirng]]
    [PvsDomain = [string]]
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **Name**: Name of the Citrix XenDesktop 7 machine catalog to create.
* **Description**: Description of the Citrix XenDesktop 7 machine catalog.
* **Allocation**: Machine catalog allocation type. Supported values are Permanent, Randam or Static.
* **Provisioning**: Machine catalog provisioning type. Supported values are Manual, PVS or MCS.
* **Persistence**: User settings persistence type. Supported values are Discard, Local or PVD.
* **IsMultiSession**: Flags the machine catalog supports multiple concurrent sessions on each machine.
* **PvsAddress**: Address of the PVS server. This option is only required if the provisioning type is set to PVS.
* **PvsDomain**: Domain of the PVS server. This option is only required if the provisioning type is set to PVS.
* **Ensure**: Whether the catalog is to be available or not. Supported values are Present or Absent. If not specified, it defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to create the catalog. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7CatalogExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7Catalog XD7CatalogExample {
        Name = 'My Machine Catalog'
        Description = 'Random manual Citrix XenApp 7.6 machine catalog'
        Allocation = 'Random'
        Provisioning = 'Manual'
        Persistence = 'Local'
        IsMultisession = $true
    }
}
```
XD7CatalogMachine
==========
Adds/assigns an Active Directory machine to a Citrix XenDesktop 7 machine catalog.
###Syntax
```
XD7CatalogMachine [string]
{
    Name = [string]
    Members = [string[]]
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **Name**: Name of the Citrix XenDesktop 7 machine catalog to add the members to.
* **Members**: One or more Active Directory computers accounts to add to the machine catalog.
* **Ensure**: Whether the computer accounts should be present or not. Supported values are Present or Absent. If not specified, it defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to machines to the catalog. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7CatalogMachineExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7CatalogMachine XD7CatalogMachineExample {
        Name = 'My Machine Catalog'
        Members = 'Domain\ComputerA','ComputerB'
        Ensure = 'Present'
    }
}
```
XD7Controller
=============
Adds or removes a Citrix XenDesktop 7 controller to or from a Citrix XenDesktop site.
###Syntax
```
XD7Controller [string]
{
    SiteName = [string]
    ExistingControllerName = [string]
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **SiteName**: Citrix XenDesktop 7 site name to join.
* **ExistingControllerName**: Existing Citrix XenDesktop 7 site controller used to join the site.
* **Ensure**: Whether the site controller should be present or not. Supported values are Present or Absent. If not specified, it defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to add or remove the controller from the site. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7Controller {
    Import-DscResource -ModuleName XenDesktop7
    XD7Controller MyXD7Controller {
        SiteName = 'My Site'
        ExistingControllerName = 'controller-a.lab.local'
        Ensure = 'Present'
    }
}
```
XD7Database
===========
Creates a Citrix XenDesktop 7 site, logging or monitor database. This resource does not support
removing or relocation of site databases.
###Syntax
```
XD7Database [string]
{
    SiteName = [string]
    DatabaseName = [string]
    DatabaseServer = [string]
    DataStore = [string] { Site | Logging | Monitor }
    [Credential = [PSCredential]]
}
```
###Properties
* **SiteName**: Citrix XenDesktop 7 site name assigned to the database.
* **DatabaseName**: Name of the Microsoft SQL database to create.
* **DatabaseServer**: FQDN of the Microsoft SQL server to host the database.
* **DataStore**: Citrix XenDesktop site database type to create.
* **Credential**: Specifies optional credential of a user which has permissions to create the database. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7Database {
    Import-DscResource -ModuleName XenDesktop7
    XD7Database MyXD7LoggingDatabase {
        SiteName = 'My Site'
        DatabaseName = 'MySiteLoggingDatabase'
        DatabaseServer = 'mysqlserver.lab.local'
        DataStore = 'Logging'
    }
}
```
XD7DesktopGroup
===============
Creates a Citrix XenDesktop 7 desktop group.
###Syntax
```
XD7DesktopGroup [string]
{
    Name = [string]
    IsMultiSession = [bool]
    DeliveryType = [string] { AppsOnly | DesktopsOnly | DesktopsAndApps }
    DesktopType = [string] { Shared | Private }
    [Description = [string]
    [DisplayName = [string]]
    [Enabled = [bool]]
    [ColorDepth = [string] { FourBit | EightBit | SixteenBit | TwentyFourBit }]
    [IsMaintenanceMode = [bool]]
    [IsRemotePC = [bool]]
    [IsSecureIca = [bool]]
    [ShutdownDesktopsAfterUse = [bool]]
    [TurnOnAddedMachine = [bool]]
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **Name**: Name of the Citrix XenDesktop 7 desktop group.
* **IsMultiSession**: Flags whether the desktop group supports multisession hosts.
* **DeliveryType**: Delivery type of the desktop group. Supported values are AppsOnlys, DesktopsOnly or DesktopsAndApps.
* **DesktopType**: Desktop allocation type. Supported values are Shared and Private.
* **Description**: Description of the desktop group.
* **DisplayName**: Display name of the desktop group.
* **Enabled**: Whether the desktop group is enabled. If not specified, this value defaults to True.
* **ColorDepth**: Color depth of the desktop group. Supported values are FourBit, EightBit, SixteenBit and TwentyFourBit. If not specified, a default value of TwentyFour bit is used.
* **IsMaintenanceMode**: Flags whether the desktop group is in maintenance mode. If not specified, this value defaults to False.
* **IsRemotePC**: Flags whether the desktop group is a RemotePC desktop group. If not specified, this value defaults to False.
* **IsSecureIca**: Flags whether Secure ICA is enabled/enforced.  If not specified, this value defaults to True.
* **ShutdownDesktopsAfterUse**: Flags whether virtual desktops are powered off after use.  If not specified, this value defaults to False.
* **TurnOnAddedMachine**: Flags whether machines added to the desktop group are automatically powered on.  If not specified, this value defaults to False.
* **Ensure**: Specifies whether the desktop group is present or not. If not specified, this value defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to create the desktop group. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7DesktopGroupExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7DesktopGroup MyXD7DesktopGroup {
        SiteName = 'My Desktop Group'
        IsMultiSession = $true
        DeliveryType = 'DesktopsAndApps'
        DesktopType = 'Shared'
    }
}
```
XD7DesktopGroupMember
=====================
Adds or removes Active Directory computer accounts to or from a Citrix XenDesktop 7 desktop group.
###Syntax
```
XD7DesktopGroupMember [string]
{
    Name = [string]
    Members = [string[]]
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **Name**: Name of the desktop group to allocate members to. 
* **Members**: Active Directory computer account names to assign to the desktop group.
* **Ensure**: Specifies whether the specified Active Directory computer accounts are present in the desktop group or not. If not specified, this value defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to modify the desktop group. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7DesktopGroupMemberExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7DesktopGroupMember MyXD7DesktopGroupMembers {
        Name = 'My Desktop Group'
        Members = 'computer1.lab.local','computer2.lab.local'
        Ensure = 'Present'
    }
}
```
XD7DesktopGroupApplication
==========================
Adds or removes published applications to or from a Citrix XenDesktop 7 desktop/delivery group.
###Syntax
```
XD7DesktopGroupApplication [string]
{
    Name = [string]
    DesktopGroupName = [string]
    Path = [string]
    [ApplicationType = [string] { HostedOnDesktop, InstalledOnClient }]
    [WorkingDirectory = [string]]
    [Arguments = [string]]
    [Description = [string]]
    [DisplayName = [string]]
    [Enabled = [bool]]
    [Visible = [bool]]
    [Ensure = [string]] { Present | Absent }
    [Credential = [PSCredential]]
}
```
###Properties
* **Name**: Name of the desktop application to publish.
* **DesktopGroupName**: Name of the desktop/delivery group to publish the application.
* **Path**: Path to the application executable.
* **ApplicationType**: Specifies the type of application.
 * If not specified, this value defaults to HostedOnDesktop (published).
 * __NOTE: It is not possible to change the application type after it's created.__
* **WorkingDirectory**: Working directory of the application.
* **Arguments**: Command line arguments of the application.
* **Description**: Application description.
* **DisplayName**: Name of the application displayed to the user.
* **Enabled**: Specifies whether the application is enabled.
 * If not specifed, this value defaults to $true.
* **Visible**: Specifies whether the application is visible to the user.
 * If not specifed, this value defaults to $true.
* **Ensure**: Specifies whether the specified application is published in the desktop delivery group or not.
 * If not specified, this value defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to modify the desktop group. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7DesktopGroupApplicationExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7DesktopGroupApplication XD7DesktopGroupApplicationExample {
        Name = 'Adobe Reader DC'
        DesktopGroupName = 'My Desktop Group'
        Path = 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe'
        WorkingDirectory = 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader'
        Ensure = 'Present'
    }
}
```
XD7EntitlementPolicy
====================
Grants Active Directory users/groups access to a Citrix XenDesktop 7 desktop group.
###Syntax
```
XD7EntitlementPolicy [string]
{
    DeliveryGroup = [string]
    EntitlementType = [string] EntitlementType { Desktop | Application }
    [Enabled = [bool]]
    [Name = [string]]
    [Description = [string]]
    [IncludeUsers = [string[]]]
    [ExcludeUsers = [string[]]]
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **DeliveryGroup**: The name of the delivery group to include and/or exclude users to.
* **EntitlementType**: Whether the entitlement is applies to a desktop or an application.
* **Enabled**: Flags whether the entitlement is enabled. If not specified, this value defaults to True.
* **Name**: Name of entitlement. If not specified, it defaults to ...
* **Description**: Optional description of the entitlement.
* **IncludeUser**: Users(s) explicitly included in the entitlement.
* **ExcludeUser**: User(s) explicitly excluded from the entitlement.
* **Ensure**: Whether the entitlement policy is present or not. If not specified, this value defaults to True.
* **Credential**: Specifies optional credential of a user which has permissions to create the entitlement. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7EntitlementPolicyExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7EntitlementPolicy XD7DesktopEntitlementPolicy {
        Name = 'My Desktop Group'
        EntitlementType = 'Desktop'
        IncludeUsers = 'MyDesktopGroupUsers','UserA'
    }
}
```
XD7Feature
===========
Installs Citrix XenDesktop 7 server role/feature.
###Syntax
```
XD7Feature [string]
{
    Role = [string] { Controller | Licensing | Storefront | Studio | Director }
    SourcePath = [string]
    [[Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **Role**: The Citrix XenDesktop 7.x role/feature to install.
* **SourcePath**: Location of the extracted Citrix XenDesktop 7.x setup media.
* **Ensure**: Whether the role is to be installed or not. Supported values are Present or Absent. If not specified, it defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to access the source media and/or install/uninstall the specified role.

###Configuration
```
Configuration XD7FeatureExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7Feature XD7ControllerFeature {
        Role = 'Controller'
        SourcePath = 'C:\Sources\XenDesktop76'
        Ensure = 'Present'
    }
}
```
XD7Role
=======
Assigns a Citrix XenDesktop 7 delegated security role to an administrator. This resource
does not currently support creating new Citrix XenDesktop 7 roles.
###Syntax
```
XD7Role [string]
{
    Name = [string]
    Members = string[]
    RoleScope = [string[
    [Ensure = [string] { Present | Absent }]
    [Credential = [PSCredential]]
}
```
###Properties
* **Name**: Name of an existing Citrix XenDesktop 7 role to assign or unassign an administrator to/from.
* **Members**: Name(s) of the Citrix XenDesktop 7 administrator(s) to assign or unassign.
* **RoleScope**: Name of an existing Citrix XenDesktop 7 scope to apply to the assignment. If not specified, the value defaults to All.
* **Ensure**: Whether the role member(s) should be assigned to the role or note. If not specified, this value defaults to Present.
* **Credential**: Specifies optional credential of a user which has permissions to update the role membership. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7RoleExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7Role XD7RoleAssignment {
        Name = 'Full Administrator'
        Members = 'Citrix Admins'
        EntitlementType = 'Desktop'
        IncludeUsers = 'MyDesktopGroupUsers','UserA'
    }
}
```
XD7Site
=======
Creates a new Citrix XenDesktop 7 site.
###Syntax
```
XD7Site [string]
{
    SiteName = [string]
    DatabaseServer = [string]
    SiteDatabaseName = [string]
    LoggingDatabaseName = [string]
    MonitorDatabaseName = [string]
    [Credential = [PSCredential]]
}
```
###Properties
* **SiteName**: Name of the new Citrix XenDesktop 7 site.
* **DatabaseServer**: Name of the MS SQL server hosting the Citrix XenDesktop 7 site databases.
* **SiteDatabaseName**: Name of the existing Citrix XenDesktop 7 site database.
* **LoggingDatabaseName**: Name of the existing Citrix XenDesktop 7 logging database.
* **MonitorDatabaseName**: Name of the existing Citrix XenDesktop 7 monitor database.
* **Credential**: Specifies optional credential of a user which has permissions to create the site and access the MS SQL databases. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7SiteExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7Site XD7SiteCreation {
        SiteName = 'My Site'
        DatabaseServer = 'mysqlserver.lab.local'
        SiteDatabaseName = 'MySiteDatabase'
        LoggingDatabaseName = 'MyLoggingDatabase'
        MonitorDatabaseName = 'MyMonitorDatabase'
    }    
}
```
XD7SiteLicense
==============
Configures a Citrix XenDesktop 7 licensing scheme.
###Syntax
```
XD7SiteLicense [string]
{
    LicenseServer = [string]]
    [LicenseServerPort = [uint16]]
    [LicenseEdition [string] { PLT | ENT | VDI }]
    [LicenseModel = [string] { UserDevice | Concurrent }]
    [TrustLicenseServerCertificate = [bool]]
    [Credential = [PSCredential]]
}
```
###Properties
* **LicenseServer**: Name of the exisiting Citrix license server.
* **LicenseServerPort**: Port number of the existing Citrix license server. If not specified, the value defaults to 27000.
* **LicenseEdition**: Citrix XenDesktop 7 site licensed edition to apply. Valid values are PLT, ENT or VDI. If not specified, a default value of PLT is used.
* **LicenseModel**: Citrix XenDesktop 7 site license model to apply. Valid values are UserDevice or Concurrent. If not specified, a default value of UserDevice is used.
* **TrustLicenseServerCertificate**: Flags whether the Citrix license server certificate should be trusted. If not specified, this value defaults to True.
* **Credential**: Specifies optional credential of a user which has permissions to update the site licensing. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7SiteLicenseExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7SiteLicense XD7SiteLicensing {
        LicenseServer = 'citrixls.lab.local'
    }    
}
```
XD7VDAController
================
Assigns a Citrix XenDesktop Controller to a Citrix Virtual Delivery Agent (VDA).
###Syntax
```
XD7VDAController [string]
{
    Name = [string]
    [Ensure = [string] { Present | Absent }]
}
```
###Properties
* **Name**: Name of the Citrix XenDesktop 7 Delivery Controller to assign to the VDA.
* **Ensure**: Specifies whether the Citrix XenDesktop 7 controller entry should be present or not. If not specified, the value defaults to Present.

###Configuration
```
Configuration XD7VDAControllerExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7VDAController XD7VDAController1 {
        Name = 'controller1.lab.local'
    }
    XD7VDAController XD7VDAController2 {
        Name = 'controller2.lab.local'
    }    
}
```
XD7VDAFeature
=============
Installs Citrix XenDesktop 7 Virtual Delivery Agent (VDA) feature.
###Syntax
```
XD7VDAFeature [string]
{
    Role = [string] { DesktopVDA | SessionVDA }
    SourcePath = [string]
    [InstallReceiver = [bool]]
    [EnableRemoteAssistance = [bool]]
    [Optimize = [bool]]
    [InstallDesktopExperience = [bool]]
    [EnableRealTimeTransport = [bool]]
    [Ensure = [string] { Present | Absent }]
}
```
###Properties
* **Role**: The Citrix XenDesktop 7 VDA feature to install.
* **SourcePath**: Location of the extracted Citrix XenDesktop 7 setup media.
* **InstallReceiver**: Flags whether to install the Citrix Receiver. If not specified, the value defaults to False.
* **EnableRemoteAssistance**: Flags whether to enable Remote Assistance during installation. If not specified, the value defaults to True.
* **Optimize**: Flags whether to optimize a VDA. This is only applicable to virtual machines. If not specified, the value defaults to False.
* **InstallDesktopExperience**: Flags whether to install the Windows Desktop Experience feature. This is only applicable to server operating systems. If not specified, the value defaults to True.
* **EnableRealTimeTransport**: Flags whether to enable UDP Real-time transport feature during install. If not specified, this value defaults to False.
* **Ensure**: Whether the role is to be installed or not. Supported values are Present or Absent. If not specified, it defaults to Present.

###Configuration
```
Configuration XD7VDAFeatureExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7VDAFeature XD7DeskopVDAFeature {
        Role = 'DesktopVDA'
        SourcePath = 'C:\Sources\XenDesktop76'
        InstallReceiver = $true
        Optimize = $true
    }
}
```
XD7WaitForSite
==============
Waits for a Citrix XenDesktop 7 site to become available.
###Syntax
```
XD7WaitForSite [string]
{
    SiteName = [string]
    ExistingControllerName = [string]
    [RetryIntervalSec = [uint64]]
    [RetryCount = [uint32]]
    [Credential = [PSCredential]]    
}
```
###Properties
* **SiteName**: Citrix XenDesktop 7 site to wait for.
* **ExistingControllerName**: Name of an existing Citrix XenDesktop 7 site controller to check for site availavility.
* **RetryIntervalSec**: Number of seconds between retries. If not specified, the value defaults to 30 seconds.
* **RetryCount**: Number of attempts to try before giving up. If not specified, the value default to 10.
* **Credential**: Specifies optional credential of a user which has permissions to communicate with the existing site controller. __This property is required for Powershell 4.0.__

###Configuration
```
Configuration XD7WaitForSiteExample {
    Import-DscResource -ModuleName XenDesktop7
    XD7WaitForSite XD7WaitForMySite {
        SiteName = 'My Site'
        ExistingControllerName = 'controller1.lab.local'
    }
}
```
