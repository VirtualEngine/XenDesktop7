Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateSet('Permanent','Random','Static')] [System.String] $Allocation,
        [Parameter(Mandatory)] [ValidateSet('Manual','PVS','MCS')] [System.String] $Provisioning,
        [Parameter(Mandatory)] [ValidateSet('Discard','Local','PVD')] [System.String] $Persistence,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsMultiSession = $false,
        [Parameter()] [AllowNull()] [System.String] $Description,
        [Parameter()] [AllowNull()] [System.String] $PvsAddress,
        [Parameter()] [AllowNull()] [System.String] $PvsDomain,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.DelegatedAdmin.Admin.V1 module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            param (
                [System.String] $Name
            )
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerCatalog = Get-BrokerCatalog -Name $Name;
            $targetResource = @{
                Name = $brokerCatalog.Name;
                Allocation = $brokerCatalog.AllocationType.ToString();
                Provisioning = $brokerCatalog.ProvisioningType.ToString();
                Description = $brokerCatalog.Description;
                PvsAddress = $brokerCatalog.PvsAddress;
                PvsDomain = $brokerCatalog.PvsDomain;
                IsMultiSession = $brokerCatalog.SessionSupport -eq 'MultiSession';
            }
            switch ($brokerCatalog.PersistUserChanges) {
                'OnLocal' { $targetResource['Persistence'] = 'Local'; }
                'OnPvd' { $targetResource['Persistence'] = 'PVD'; }
                'Discard' { $targetResource['Persistence'] = 'Discard'; }
            }
            return $targetResource;
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($Name);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        $targetResource = Invoke-Command  @invokeCommandParams;
        $targetResource['Ensure'] = $Ensure;
        $targetResource['Credential'] = $Credential;
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateSet('Permanent','Random','Static')] [System.String] $Allocation,
        [Parameter(Mandatory)] [ValidateSet('Manual','PVS','MCS')] [System.String] $Provisioning,
        [Parameter(Mandatory)] [ValidateSet('Discard','Local','PVD')] [System.String] $Persistence,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsMultiSession = $false,
        [Parameter()] [AllowNull()] [System.String] $Description,
        [Parameter()] [AllowNull()] [System.String] $PvsAddress = $null,
        [Parameter()] [AllowNull()] [System.String] $PvsDomain = $null,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $PSBoundParameters['Ensure'] = $Ensure;
        $targetResource = Get-TargetResource @PSBoundParameters;
        $inCompliance = $true;
        foreach ($property in $targetResource.Keys) {
            if ($targetResource.$property -ne $PSBoundParameters.$property) {
                Write-Verbose ($localizedData.MachineCatalogPropertyMismatch -f $property, $PSBoundParameters.$property, $targetResource.$property);
                $inCompliance = $false;
            }
        }
        if ($inCompliance) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $Name);
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $Name);
        }
        return $inCompliance;
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateSet('Permanent','Random','Static')] [System.String] $Allocation,
        [Parameter(Mandatory)] [ValidateSet('Manual','PVS','MCS')] [System.String] $Provisioning,
        [Parameter(Mandatory)] [ValidateSet('Discard','Local','PVD')] [System.String] $Persistence,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsMultiSession = $false,
        [Parameter()] [AllowNull()] [System.String] $Description,
        [Parameter()] [AllowNull()] [System.String] $PvsAddress,
        [Parameter()] [AllowNull()] [System.String] $PvsDomain,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.DelegatedAdmin.Admin.V1 module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            param (
                [System.String] $Name,
                [System.String] $Ensure,
                [System.String] $Allocation,
                [System.String] $Provisioning,
                [System.String] $Persistence,
                [System.Boolean] $IsMultiSession,
                [System.String] $Description,
                [System.String] $PvsAddress,
                [System.String] $PvsDomain
            )
            data localizedData {
                ConvertFrom-StringData @'    
    ChangingMachineCatalogUnsupportedWarning = Changing '{0}' Citrix XenDesktop 7.x Machine Catalog '{1}' type is not supported. Machine catalog will be recreated.
    CreatingMachineCatalog = Creating Citrix XenDesktop 7.x Machine Catalog '{0}'.
    UpdatingMachineCatalog = Updating Citrix XenDesktop 7.x Machine Catalog '{0}'.
    RemovingMachineCatalog = Removing Citrix XenDesktop 7.x Machine Catalog '{0}'.
'@
            }
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerCatalog = Get-BrokerCatalog -Name $Name -ErrorAction SilentlyContinue;
            if ($Ensure -eq 'Present') {
                if ($brokerCatalog) {
                    $recreateMachineCatalog = $false;
                    if ($brokerCatalog.AllocationType -ne $Allocation) {
                        Write-Warning ($localizedData.ChangingMachineCatalogUnsupportedWarning -f $Name, 'Allocation');
                        $recreateMachineCatalog = $true;
                    }
                    elseif ($brokerCatalog.ProvisioningType -ne $Provisioning) {
                        Write-Warning ($localizedData.ChangingMachineCatalogUnsupportedWarning -f $Name, 'Provisioning');
                        $recreateMachineCatalog = $true;
                    }
                    elseif (($brokerCatalog.PersistUserChanges -replace 'On', '') -ne $Persistence) {
                        Write-Warning ($localizedData.ChangingMachineCatalogUnsupportedWarning -f $Name, 'Persistence');
                        $recreateMachineCatalog = $true;
                    }
                    elseif ($brokerCatalog.SessionSupport -eq 'Multisession' -and $IsMultiSession -ne $true) {
                        Write-Warning ($localizedData.ChangingMachineCatalogUnsupportedWarning -f $Name, 'Session');
                        $recreateMachineCatalog = $true; 
                    }
            
                    if ($recreateMachineCatalog) {
                        Write-Verbose ($localizedData.RemovingMachineCatalog -f $Name);
                        Remove-BrokerCatalog -Name $Name;
                        $brokerCatalog = $null;
                    }
                    else {
                        Write-Verbose ($localizedData.UpdatingMachineCatalog -f $Name);
                        $setBrokerCatalogParams = @{
                            Name = $Name;
                            Description = $Description;
                        }
                        if ($PvsDomain) { $setBrokerCatalogParams['PvsDomain'] = $PvsDomain; }
                        if ($PvsAddress) { $setBrokerCatalogParams['PvsAddress'] = $PvsAddress; }
                        Set-BrokerCatalog @setBrokerCatalogParams;
                    }
                } #end if brokerCatalog
        
                if (-not $brokerCatalog) {
                    $newBrokerCatalogParams = @{
                        Name = $Name;
                        AllocationType = $Allocation;
                        SessionSupport = 'SingleSession';
                        ProvisioningType = $Provisioning;
                        PersistUserChanges = 'Discard';
                    }
                    if ($Provisioning -eq 'Manual') {
                        $newBrokerCatalogParams['MachinesArePhysical'] = $true;
                    }
                    if ($Description) {
                        $newBrokerCatalogParams['Description'] = $Description;
                    }
                    if ($PvsAddress) {
                        $newBrokerCatalogParams['PvsAddress'] = $PvsAddress;
                    }
                    if ($PvsDomain) {
                        $newBrokerCatalogParams['PvsDomain'] = $PvsDomain;
                    }
                    if ($IsMultiSession) {
                        $newBrokerCatalogParams['SessionSupport'] = 'MultiSession';
                    }
                    if ($Persistence -eq 'Local') {
                        $newBrokerCatalogParams['PersistUserChanges'] = 'OnLocal';
                    }
                    elseif ($Persistence -eq 'PVD') {
                        $newBrokerCatalogParams['PersistUserChanges'] = 'OnPvd';
                    }
                    Write-Verbose ($localizedData.CreatingMachineCatalog -f $Name);
                    New-BrokerCatalog @newBrokerCatalogParams;
                }
            }
            else {
                Write-Verbose ($localizedData.RemovingMachineCatalog -f $Name);
                Remove-BrokerCatalog -Name $Name;
            }
        } #end scriptBlock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($Name, $Ensure, $Allocation, $Provisioning, $Persistence, $IsMultiSession, $Description, $PvsAddress, $PvsDomain);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
