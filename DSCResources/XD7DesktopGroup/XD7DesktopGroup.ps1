Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Boolean] $IsMultiSession,
        [Parameter(Mandatory)] [ValidateSet('AppsOnly','DesktopsOnly','DesktopsAndApps')] [System.String] $DeliveryType,
        [Parameter(Mandatory)] [ValidateSet('Private','Shared')] [System.String] $DesktopType, # Type?
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Description = $Name,
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $DisplayName = $Name,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $Enabled = $true,
        [Parameter()] [ValidateSet('FourBit','EightBit','SixteenBit','TwentyFourBit')] [System.String] $ColorDepth = 'TwentyFourBit',
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsMaintenanceMode = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsRemotePC = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsSecureIca = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $ShutdownDesktopsAfterUse = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $TurnOnAddedMachine = $false,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.Broker.Admin.V2' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
        
            $deliveryGroup = Get-BrokerDesktopGroup -Name $using:Name -ErrorAction SilentlyContinue;
            $targetResource = @{
                Name = $using:Name;
                IsMultiSession = $deliveryGroup.SessionSupport -eq 'MultiSession';
                DeliveryType = [System.String] $deliveryGroup.DeliveryType;
                Description = $deliveryGroup.Description;
                DisplayName = $deliveryGroup.PublishedName;
                DesktopType = [System.String] $deliveryGroup.DesktopKind;
                Enabled = $deliveryGroup.Enabled;
                ColorDepth = [System.String] $deliveryGroup.ColorDepth;
                IsMaintenanceMode = $deliveryGroup.InMaintenanceMode;
                IsRemotePC = $deliveryGroup.IsRemotePC;
                IsSecureICA = $deliveryGroup.SecureIcaRequired;
                ShutdownDesktopsAfterUse = $deliveryGroup.ShutdownDesktopsAfterUse;
                TurnOnAddedMachine = $deliveryGroup.TurnOnAddedMachine
                Ensure = 'Absent';
                Credential = $using:Credential;
            }
            if ($deliveryGroup) { $targetResource['Ensure'] = 'Present'; }
            return $targetResource;
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        $scriptBlockParams = @($Name,$Description,$DeliveryType,$PublishedName,$ColorDepth,$Enabled,$IsMaintenanceMode,$IsRemotePC,$IsSecureIca,$ShutdownDesktopsAfterUse,$TurnOnAddedMachine);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        $targetResource = Invoke-Command  @invokeCommandParams;
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Boolean] $IsMultiSession,
        [Parameter(Mandatory)] [ValidateSet('AppsOnly','DesktopsOnly','DesktopsAndApps')] [System.String] $DeliveryType,
        [Parameter(Mandatory)] [ValidateSet('Private','Shared')] [System.String] $DesktopType, # Type?
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Description = $Name,
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $DisplayName = $Name,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $Enabled = $true,
        [Parameter()] [ValidateSet('FourBit','EightBit','SixteenBit','TwentyFourBit')] [System.String] $ColorDepth = 'TwentyFourBit',
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsMaintenanceMode = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsRemotePC = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsSecureIca = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $ShutdownDesktopsAfterUse = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $TurnOnAddedMachine = $false,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        $isInCompliance = $true;
        if ($targetResource['Ensure'] -ne $Ensure) { $isInCompliance = $false; }
        elseif ($targetResource['IsMultiSession'] -ne $IsMultiSession) { $isInCompliance = $false; }
        elseif ($targetResource['DeliveryType'] -ne $DeliveryType) { $isInCompliance = $false; }
        elseif ($targetResource['Description'] -ne $Description) { $isInCompliance = $false; }
        elseif ($targetResource['DesktopType'] -ne $DesktopType) { $isInCompliance = $false; }
        elseif ($targetResource['DisplayName'] -ne $DisplayName) { $isInCompliance = $false; }
        elseif ($targetResource['Enabled'] -ne $Enabled) { $isInCompliance = $false; }
        elseif ($targetResource['ColorDepth'] -ne $ColorDepth) { $isInCompliance = $false; }
        elseif ($targetResource['IsMaintenanceMode'] -ne $IsMaintenanceMode) { $isInCompliance = $false; }
        elseif ($targetResource['IsRemotePC'] -ne $IsRemotePC) { $isInCompliance = $false; }
        elseif ($targetResource['IsSecureIca'] -ne $IsSecureIca) { $isInCompliance = $false; }
        elseif ($targetResource['ShutdownDesktopsAfterUse'] -ne $ShutdownDesktopsAfterUse) { $isInCompliance = $false; }
        elseif ($targetResource['TurnOnAddedMachine'] -ne $TurnOnAddedMachine) { $isInCompliance = $false; }
        if ($isInCompliance) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $Name);
            return $true;
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $Name);
            return $false;
        }
    } #end process
} #end function Get-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Boolean] $IsMultiSession,
        [Parameter(Mandatory)] [ValidateSet('AppsOnly','DesktopsOnly','DesktopsAndApps')] [System.String] $DeliveryType,        
        [Parameter(Mandatory)] [ValidateSet('Private','Shared')] [System.String] $DesktopType, # Type?
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Description = $Name,
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $DisplayName = $Name,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $Enabled = $true,
        [Parameter()] [ValidateSet('FourBit','EightBit','SixteenBit','TwentyFourBit')] [System.String] $ColorDepth = 'TwentyFourBit',
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsMaintenanceMode = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsRemotePC = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $IsSecureIca = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $ShutdownDesktopsAfterUse = $false,
        [Parameter()] [ValidateNotNull()] [System.Boolean] $TurnOnAddedMachine = $false,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.Broker.Admin.V2' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            Import-Module "$env:ProgramFiles\WindowsPowerShell\Modules\CitrixXenDesktop7\DSCResources\XD7Common\XD7Common.psd1" -Verbose:$false;
        
            $deliveryGroup = Get-BrokerDesktopGroup -Name $using:Name -ErrorAction SilentlyContinue;
            if ($using:Ensure -eq 'Present') {
                $brokerDeliveryGroupParams = @{
                    Name = $using:Name;
                    Description = $using:Description;
                    DeliveryType = $using:DeliveryType;
                    PublishedName = $using:DisplayName;
                    ColorDepth = $using:ColorDepth;
                    Enabled = $using:Enabled;
                    InMaintenanceMode = $using:IsMaintenanceMode;
                    IsRemotePC = $using:IsRemotePC;
                    SecureIcaRequired = $using:IsSecureIca;
                    ShutdownDesktopsAfterUse = $using:ShutdownDesktopsAfterUse;
                    TurnOnAddedMachine = $using:TurnOnAddedMachine
                }
                if ($deliveryGroup) {
                    if ($using:IsMultiSession) { $sessionSupport = 'MultiSession'; }
                    else { $sessionSupport = 'SingleSession'; }
                    ## ! No SessionSupport or DesktopKind - DeleteIfNeeded option? RemoveExistingIfNeeded/Required?
                    if ($sessionSupport -ne $deliveryGroup.SessionSupport) {
                        ThrowInvalidOperationException -ErrorId 'ImmutableProperty' -ErrorMessage ($using:localizedData.ImmutablePropertyError -f 'IsMultiSession');
                    }
                    elseif ($DesktopType -ne $deliveryGroup.DesktopKind) {
                        ThrowInvalidOperationException -ErrorId 'ImmutableProperty' -ErrorMessage ($using:localizedData.ImmutablePropertyError -f 'DesktopType');
                    }
                    Write-Verbose ($using:localizedData.UpdatingDeliveryGroup -f $using:Name);
                    Set-BrokerDesktopGroup @brokerDeliveryGroupParams;
                }
                else {
                    if ($using:IsMultiSession) { $brokerDeliveryGroupParams['SessionSupport'] = 'MultiSession'; }
                    else { $brokerDeliveryGroupParams['SessionSupport'] = 'SingleSession'; }
                    $brokerDeliveryGroupParams['DesktopKind'] = $using:DesktopType;
                    Write-Verbose ($localizedData.AddingDeliveryGroup -f $using:Name);
                    New-BrokerDesktopGroup @brokerDeliveryGroupparams;
                }
            }
            elseif ($deliveryGroup -and ($using:Ensure -eq 'Absent')) {
                Write-Verbose ($using:localizedData.RemovingDeliveryGroup -f $using:Name);
                Remove-BrokerDesktopGroup -InputObject $deliveryGroup;
            }
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        $scriptBlockParams = @($Name,$Description,$DeliveryType,$PublishedName,$ColorDepth,$Enabled,$IsMaintenanceMode,$IsRemotePC,$IsSecureIca,$ShutdownDesktopsAfterUse,$TurnOnAddedMachine);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
