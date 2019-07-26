@{
    ModuleVersion        = '2.8.1';
    GUID                 = '3bacd95f-494b-4ea2-989b-09cb5e324940';
    Author               = 'Iain Brighton';
    CompanyName          = 'Virtual Engine';
    Copyright            = '(c) 2019 Virtual Engine Limited. All rights reserved.';
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
                                'XD7Features',
                                'XD7Role',
                                'XD7Site',
                                'Xd7SiteConfig',
                                'XD7SiteLicense',
                                'XD7StoreFront',
                                'XD7StoreFrontAccountSelfService',
                                'XD7StoreFrontAuthenticationMethod',
                                'XD7StoreFrontAuthenticationService',
                                'XD7StoreFrontBaseUrl',
                                'XD7StoreFrontExplicitCommonOptions',
                                'XD7StoreFrontFarmConfiguration',
                                'XD7StoreFrontFilterKeyword',
                                'XD7StoreFrontOptimalGateway',
                                'XD7StoreFrontPNA',
                                'XD7StoreFrontReceiverAuthenticationMethod',
                                'XD7StoreFrontRegisterStoreGateway',
                                'XD7StoreFrontRoamingBeacon',
                                'XD7StoreFrontRoamingGateway',
                                'XD7StoreFrontSessionStateTimeout',
                                'XD7StoreFrontStore',
                                'XD7StoreFrontStoreFarm',
                                'XD7StoreFrontUnifiedExperience',
                                'XD7StoreFrontWebReceiverCommunication',
                                'XD7StoreFrontWebReceiverPluginAssistant',
                                'XD7StoreFrontWebReceiverResourcesService',
                                'XD7StoreFrontWebReceiverService',
                                'XD7StoreFrontWebReceiverSiteStyle',
                                'XD7StoreFrontWebReceiverUserInterface',
                                'XD7VDAController',
                                'XD7VDAFeature',
                                'XD7WaitForSite'
                            );
    PrivateData = @{
        PSData = @{
            Tags       = @('VirtualEngine','Citrix','XenDesktop','XenApp','Storefront','DSC');
            LicenseUri = 'https://github.com/VirtualEngine/XenDesktop7/blob/master/LICENSE';
            ProjectUri = 'https://github.com/VirtualEngine/XenDesktop7';
            IconUri    = 'https://raw.githubusercontent.com/VirtualEngine/XenDesktop7/master/CitrixReceiver.png';
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
