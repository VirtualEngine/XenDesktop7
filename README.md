Included Resources
==================
* cXD7Role

cXD7Role
===========

###Syntax
```
cXD7Role [string]
{
    Role = [string]
    SourcePath = [string]
    [Ensure = [string]]
    [Credential = [PSCredential]]
```
###Properties
* Role: The Citrix XenDesktop 7.x role to install. Supported values are Controller, Studio, Licensing, Storefront, Director, SessionVDA or DesktopVDA.
* SourcePath: Location of the extracted Citrix XenDesktop 7.x setup media.
* Ensure: Whether the role is to be installed or not. Supported values are Present or Absent. If not specified, it defaults to Present.
* Credential: Specifies optional credential of a user which has permissions to access the source media and/or install/uninstall the specified role.

###Configuration
```
Configuration cXD7RoleExample {
    Import-DscResource -ModuleName cCitrixXenDesktop7
    cXDRole XD7ControllerRole {
        Role = 'Controller'
        SourcePath = 'C:\Sources\XenDesktop76'
        Ensure = 'Present'
    }
}
```
