@{
    ModuleVersion = '2.2.5';
    GUID = '3bacd95f-494b-4ea2-989b-09cb5e324940';
    Author = 'Iain Brighton';
    CompanyName = 'Virtual Engine';
    Copyright = '(c) 2016 Virtual Engine Limited. All rights reserved.';
    Description = 'The XenDesktop7 DSC resources can automate the deployment and configuration of Citrix XenDesktop 7.x. These DSC resources are provided AS IS, and are not supported through any means.'
    PowerShellVersion = '4.0';
    CLRVersion = '4.0';
    FunctionsToExport = @('Get-TargetResource', 'Set-TargetResource', 'Test-TargetResource');
    NestedModules = @('VE_XD7AccessPolicy', 'VE_XD7Administrator', 'VE_XD7Catalog', 'VE_XD7CatalogMachine', 'VE_XD7Controller',
                        'VE_XD7Database', 'VE_XD7DesktopGroup', 'VE_XD7DesktopGroupApplication', 'VE_XD7DesktopGroupMember',
                        'VE_XD7EntitlementPolicy', 'VE_XD7Feature', 'VE_XD7Role', 'VE_XD7Site', 'VE_XD7SiteLicense',
                        'VE_XD7StoreFrontBaseUrl', 'VE_XD7VDAController', 'VE_XD7VDAFeature', 'VE_XD7WaitForSite');
    CmdletsToExport = '*';
    PrivateData = @{
        PSData = @{
            Tags = @('VirtualEngine','Citrix','XenDesktop','DSC');
            LicenseUri = 'https://github.com/VirtualEngine/XenDesktop7/blob/master/LICENSE';
            ProjectUri = 'https://github.com/VirtualEngine/XenDesktop7';
            IconUri = 'https://raw.githubusercontent.com/VirtualEngine/XenDesktop7/master/CitrixReceiver.png';
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
