# Change Log #

## Versions ##

### 2.8.1 (2019-07-26)

* Bug Fixes
  * Fix bug in XD7StoreFrontFarmConfiguration where PooledSocket and ServerCommunicationAttempts were returning incorrect values

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
