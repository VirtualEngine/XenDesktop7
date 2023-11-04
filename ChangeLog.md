# Change Log #

## Versions ##

### 2.10.2 (2023-11-04)

* Bug Fixes
  * Fixes 'XD7StoreFrontRoamingGateway\Test-TargetResource' failing when StaUrl configured (#60)

### 2.10.1 (2023-11-01)

* Bug Fixes
  * Detects Citrix PowerShell modules relocated in CVAD 1912+ (#48)
  * Adds $null check when testing for existing Access Policy policy configuration (#53)
  * Changes 'XD7StoreFrontFarmConfiguration\Get-TargetResource' to use 'Get-STFFarmConfiguration' cmdlet (#54)
  * Changes 'XD7StoreFrontOptimalGateway' schema property 'Farms' from 'Read' to 'Write' (#55)

### 2.10.0 (2020-04-01)

* Improvements
  * Adds 'IgnoreHardwareCheckFailure' property to XD7Feature and XD7Features resources (CVAD 1906+)
  * Adds 'FAS' role to XD7Feature and XD7Features resources
  * Adds 'MinimumFunctionalLevel' property to XD7Catalog

* Bug Fixes
  * Adds PsDscRunAsCredential support to XD7SiteConfig

### 2.9.0 (2020-03-02)

* Features
  * Adds XD7StoreFrontStoreBase resource
  * Adds XD7AuthenticationServiceProtocol resource

* Improvements
  * Adds SessionStateTimeout and DefaultIISSite properties to XD7StoreFrontWebReceiverService

* Bug Fixes
  * Fix bug in XD7StoreFrontFarmConfiguration where PooledSocket and ServerCommunicationAttempts were returning incorrect values
  * Fix bug in XD7StoreFrontWebReceiverService where SiteId could not be specified
  * Fix "An item with the same key has already been added" error in XD7StoreFrontStore resource
  * Adds Storefront module path to the session's $PSModulePath after feature install

### 2.8.0 (2019-07-19)

**BREAKING CHANGE** Makes '_FarmName_' property in XD7StoreFrontStore resource mandatory

* Features
  * Added new XD7StoreFrontAccountSelfService resource (via @BrianMcLain)
  * Added new XD7StoreFrontAuthenticationService resource (via @BrianMcLain)
  * Added new XD7StoreFrontPNA resource (via @BrianMcLain)
  * Added new XD7StoreFrontRoamingBeacon resource (via @BrianMcLain)
  * Added new XD7StoreFrontStoreFarm resource (via @BrianMcLain)
  * Added new XD7StoreFrontWebReceiverResourcesService resource (via @BrianMcLain)
  * Added new XD7StoreFrontWebReceiverSiteStyle resource (via @BrianMcLain)

* Improvements
  * Permits assigning multiple NetScaler gateways in StoreFrontRegisterStoreGateway resource

* Bug Fixes
  * Fixes bug in XD7StoreFrontFarmConfiguration when '_PooledSockets_' is specified
  * Fixed bug in XD7StoreFrontRoamingGateway updating gateway that was not present

### 2.7.1 (2019-04-13) ###

* Features
  * None

* Improvements
  * Implements AppVeyor build
  * Adds linting tests

* Bug fixes
  * Fixes Get-STFStoreFarm errors

### 2.7.0 (2019-04-01) ###

* Features
  * Added new XD7StoreFront resource (via @jhelmz)
  * Added new XD7StoreFrontExplicitCommonOptions resource (via @jhelmz)
  * Added new XD7StoreFrontFarmConfiguration resource (via @jhelmz)
  * Added new XD7StoreFrontFilterKeyword resource (via @jhelmz)
  * Added new XD7StoreFrontOptimalGateway resource (via @jhelmz)
  * Added new XD7StoreFrontRegisterStoreGateway resource (via @jhelmz)
  * Added new XD7StoreFrontRoamingGateway resource (via @jhelmz)
  * Added new XD7StoreFrontSessionStateTimeout resource (via @jhelmz)
  * Added new XD7StoreFrontStore resource (via @jhelmz)
  * Added new XD7StoreFrontWebReceiverCommunication (via @jhelmz)
  * Added new XD7StoreFrontWebReceiverPluginAssistant resource (via @jhelmz)
  * Added new XD7StoreFrontWebReceiverService resource (via @jhelmz)
  * Added new XD7StoreFrontWebReceiverUserInterface resource (via @jhelmz)

* Improvements
  * Updates XD7WaitForSite to use common InvokeScriptBlock function

* Bug fixes
  * None
