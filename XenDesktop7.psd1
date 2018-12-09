@{
    ModuleVersion        = '2.6.0';
    GUID                 = '3bacd95f-494b-4ea2-989b-09cb5e324940';
    Author               = 'Iain Brighton';
    CompanyName          = 'Virtual Engine';
    Copyright            = '(c) 2018 Virtual Engine Limited. All rights reserved.';
    Description          = 'The XenDesktop7 DSC resources can automate the deployment and configuration of Citrix XenDesktop 7.x. These DSC resources are provided AS IS, and are not supported through any means.'
    PowerShellVersion    = '4.0';
    DscResourcesToExport = @(
                                'XD7AccessPolicy',
                                'XD7Administrator',
                                'XD7Catalog',
                                'XD7CatalogMachine',
                                'XD7Controller',
                                'XD7Database',
                                'XD7DesktopGroup',
                                'XD7DesktopGroupApplication',
                                'XD7DesktopGroupMember',
                                'XD7EntitlementPolicy',
                                'XD7Feature',
                                'XD7Role',
                                'XD7Site',
                                'XD7SiteLicense',
                                'XD7StoreFrontBaseUrl',
                                'XD7VDAController',
                                'XD7VDAFeature',
                                'XD7WaitForSite'
                            );
    PrivateData = @{
        PSData = @{
            Tags       = @('VirtualEngine','Citrix','XenDesktop','XenApp','DSC');
            LicenseUri = 'https://github.com/VirtualEngine/XenDesktop7/blob/master/LICENSE';
            ProjectUri = 'https://github.com/VirtualEngine/XenDesktop7';
            IconUri    = 'https://raw.githubusercontent.com/VirtualEngine/XenDesktop7/master/CitrixReceiver.png';
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
