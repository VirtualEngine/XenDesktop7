Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7Catalog.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateSet('Permanent','Random','Static')]
        [System.String] $Allocation,

        [Parameter(Mandatory)]
        [ValidateSet('Manual','PVS','MCS')]
        [System.String] $Provisioning,

        [Parameter(Mandatory)]
        [ValidateSet('Discard','Local','PVD')]
        [System.String] $Persistence,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsMultiSession = $false,

        [Parameter()]
        [AllowNull()]
        [System.String] $Description,

        [Parameter()]
        [AllowNull()]
        [System.String] $PvsAddress,

        [Parameter()]
        [AllowNull()]
        [System.String] $PvsDomain,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {

        AssertXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin;

    }
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerCatalog = Get-BrokerCatalog -Name $using:Name -ErrorAction SilentlyContinue;

            $targetResource = @{
                Name = $brokerCatalog.Name;
                Allocation = [System.String] $brokerCatalog.AllocationType;
                Provisioning = [System.String] $brokerCatalog.ProvisioningType;
                Description = $brokerCatalog.Description;
                PvsAddress = $brokerCatalog.PvsAddress;
                PvsDomain = $brokerCatalog.PvsDomain;
                IsMultiSession = $brokerCatalog.SessionSupport -eq 'MultiSession';
                Ensure = $using:Ensure;
            }

            switch ($brokerCatalog.PersistUserChanges) {

                'OnLocal' {
                    $targetResource['Persistence'] = 'Local';
                }
                'OnPvd' {
                    $targetResource['Persistence'] = 'PVD';
                }
                'Discard' {
                    $targetResource['Persistence'] = 'Discard';
                }
            }

            return $targetResource;

        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
            Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name)));
            return Invoke-Command @invokeCommandParams;
        }
        else {
            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
            return & $invokeCommandParams.ScriptBlock
        }

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateSet('Permanent','Random','Static')]
        [System.String] $Allocation,

        [Parameter(Mandatory)]
        [ValidateSet('Manual','PVS','MCS')]
        [System.String] $Provisioning,

        [Parameter(Mandatory)]
        [ValidateSet('Discard','Local','PVD')]
        [System.String] $Persistence,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsMultiSession = $false,

        [Parameter()]
        [AllowNull()]
        [System.String] $Description,

        [Parameter()]
        [AllowNull()]
        [System.String] $PvsAddress,

        [Parameter()]
        [AllowNull()]
        [System.String] $PvsDomain,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    process {

        $PSBoundParameters['Ensure'] = $Ensure;
        $targetResource = Get-TargetResource @PSBoundParameters;
        $inCompliance = $true;

        foreach ($property in $PSBoundParameters.Keys) {

            if ($targetResource.ContainsKey($property)) {

                if ($targetResource[$property] -ne $PSBoundParameters[$property]) {


                    Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, $PSBoundParameters[$property], $targetResource[$property]);
                    $inCompliance = $false;
                }
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateSet('Permanent','Random','Static')]
        [System.String] $Allocation,

        [Parameter(Mandatory)]
        [ValidateSet('Manual','PVS','MCS')]
        [System.String] $Provisioning,

        [Parameter(Mandatory)]
        [ValidateSet('Discard','Local','PVD')]
        [System.String] $Persistence,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsMultiSession = $false,

        [Parameter()]
        [AllowNull()]
        [System.String] $Description,

        [Parameter()]
        [AllowNull()]
        [System.String] $PvsAddress,

        [Parameter()]
        [AllowNull()]
        [System.String] $PvsDomain,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {
        AssertXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin;
    }
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerCatalog = Get-BrokerCatalog -Name $using:Name -ErrorAction SilentlyContinue;

            if ($using:Ensure -eq 'Present') {

                if ($brokerCatalog) {

                    $recreateMachineCatalog = $false;
                    if ($brokerCatalog.AllocationType -ne $using:Allocation) {

                        Write-Warning ($using:localizedData.ChangingMachineCatalogUnsupportedWarning -f $using:Name, 'Allocation');
                        $recreateMachineCatalog = $true;
                    }
                    elseif ($brokerCatalog.ProvisioningType -ne $using:Provisioning) {

                        Write-Warning ($using:localizedData.ChangingMachineCatalogUnsupportedWarning -f $using:Name, 'Provisioning');
                        $recreateMachineCatalog = $true;
                    }
                    elseif (($brokerCatalog.PersistUserChanges -replace 'On', '') -ne $using:Persistence) {

                        Write-Warning ($using:localizedData.ChangingMachineCatalogUnsupportedWarning -f $using:Name, 'Persistence');
                        $recreateMachineCatalog = $true;
                    }
                    elseif ($brokerCatalog.SessionSupport -eq 'Multisession' -and $using:IsMultiSession -ne $true) {

                        Write-Warning ($using:localizedData.ChangingMachineCatalogUnsupportedWarning -f $using:Name, 'Session');
                        $recreateMachineCatalog = $true;
                    }

                    if ($recreateMachineCatalog) {

                        Write-Verbose ($using:localizedData.RemovingMachineCatalog -f $using:Name);
                        [ref] $null = Remove-BrokerCatalog -Name $using:Name;
                        $brokerCatalog = $null;
                    }
                    else {

                        Write-Verbose ($using:localizedData.UpdatingMachineCatalog -f $using:Name);
                        $setBrokerCatalogParams = @{
                            Name = $using:Name;
                            Description = $using:Description;
                        }

                        if ($using:PvsDomain) {

                            $setBrokerCatalogParams['PvsDomain'] = $using:PvsDomain;
                        }
                        if ($using:PvsAddress) {

                            $setBrokerCatalogParams['PvsAddress'] = $using:PvsAddress;
                        }

                        [ref] $null = Set-BrokerCatalog @setBrokerCatalogParams;

                    }
                } #end if brokerCatalog

                if (-not $brokerCatalog) {

                    $newBrokerCatalogParams = @{
                        Name = $using:Name;
                        AllocationType = $using:Allocation;
                        SessionSupport = 'SingleSession';
                        ProvisioningType = $using:Provisioning;
                        PersistUserChanges = 'Discard';
                    }

                    if ($using:Provisioning -eq 'Manual') {

                        $newBrokerCatalogParams['MachinesArePhysical'] = $true;
                    }
                    if ($using:Description) {

                        $newBrokerCatalogParams['Description'] = $using:Description;
                    }
                    if ($using:PvsAddress) {

                        $newBrokerCatalogParams['PvsAddress'] = $using:PvsAddress;
                    }
                    if ($using:PvsDomain) {

                        $newBrokerCatalogParams['PvsDomain'] = $using:PvsDomain;
                    }
                    if ($using:IsMultiSession) {

                        $newBrokerCatalogParams['SessionSupport'] = 'MultiSession';
                    }
                    if ($using:Persistence -eq 'Local') {

                        $newBrokerCatalogParams['PersistUserChanges'] = 'OnLocal';
                    }
                    elseif ($using:Persistence -eq 'PVD') {

                        $newBrokerCatalogParams['PersistUserChanges'] = 'OnPvd';
                    }

                    Write-Verbose ($using:localizedData.CreatingMachineCatalog -f $using:Name);

                    [ref] $null = New-BrokerCatalog @newBrokerCatalogParams;
                }

            }
            else {

                Write-Verbose ($using:localizedData.RemovingMachineCatalog -f $using:Name);
                [ref] $null = Remove-BrokerCatalog -Name $using:Name;
            }

        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
            $scriptBlockParams = @($Name, $Ensure, $Allocation, $Provisioning, $Persistence, $IsMultiSession, $Description, $PvsAddress, $PvsDomain);
            Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));    
            [ref] $null = Invoke-Command @invokeCommandParams;
        }
        else {
            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
            [ref] $null = & $invokeCommandParams.ScriptBlock
        }

        

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
