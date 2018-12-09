Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7DesktopGroup.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Boolean] $IsMultiSession,

        [Parameter(Mandatory)]
        [ValidateSet('AppsOnly','DesktopsOnly','DesktopsAndApps')]
        [System.String] $DeliveryType,

        [Parameter(Mandatory)]
        [ValidateSet('Private','Shared')]
        [System.String] $DesktopType, # Type?

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Description = $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $DisplayName = $Name,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [ValidateSet('FourBit','EightBit','SixteenBit','TwentyFourBit')]
        [System.String] $ColorDepth = 'TwentyFourBit',

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsMaintenanceMode = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsRemotePC = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsSecureIca = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $ShutdownDesktopsAfterUse = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $TurnOnAddedMachine = $false,

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
            }

            if ($deliveryGroup) {
                $targetResource['Ensure'] = 'Present';
            }

            return $targetResource;

        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        $scriptBlockParams = @($Name, $Description, $DeliveryType, $PublishedName, $ColorDepth, $Enabled, $IsMaintenanceMode, $IsRemotePC,
                                $IsSecureIca,$ShutdownDesktopsAfterUse,$TurnOnAddedMachine);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
            $targetResource = Invoke-Command  @invokeCommandParams;
        }
        else {
            $invokeScriptBlock = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
            $targetResource = InvokeScriptBlock -ScriptBlock $invokeScriptBlock;
        }
        return $targetResource;

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
        [ValidateNotNull()]
        [System.Boolean] $IsMultiSession,

        [Parameter(Mandatory)]
        [ValidateSet('AppsOnly','DesktopsOnly','DesktopsAndApps')]
        [System.String] $DeliveryType,

        [Parameter(Mandatory)]
        [ValidateSet('Private','Shared')]
        [System.String] $DesktopType, # Type?

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Description = $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $DisplayName = $Name,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [ValidateSet('FourBit','EightBit','SixteenBit','TwentyFourBit')]
        [System.String] $ColorDepth = 'TwentyFourBit',

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsMaintenanceMode = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsRemotePC = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsSecureIca = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $ShutdownDesktopsAfterUse = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $TurnOnAddedMachine = $false,

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

                $expected = $PSBoundParameters[$property];
                $actual = $targetResource[$property];
                if ($expected -ne $actual) {

                    Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, $expected, $actual);
                    $inCompliance = $false;
                }
            }
        }
        if ($inCompliance) {

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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Boolean] $IsMultiSession,

        [Parameter(Mandatory)]
        [ValidateSet('AppsOnly','DesktopsOnly','DesktopsAndApps')]
        [System.String] $DeliveryType,

        [Parameter(Mandatory)]
        [ValidateSet('Private','Shared')]
        [System.String] $DesktopType, # Type?

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Description = $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $DisplayName = $Name,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [ValidateSet('FourBit','EightBit','SixteenBit','TwentyFourBit')]
        [System.String] $ColorDepth = 'TwentyFourBit',

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsMaintenanceMode = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsRemotePC = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $IsSecureIca = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $ShutdownDesktopsAfterUse = $false,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $TurnOnAddedMachine = $false,

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
            ## Load modules from relative path to avoid v5 module versioning interference (#15)
            Import-Module (Join-Path -Path $using:moduleParent -ChildPath 'VE_XD7Common');

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

                    if ($using:IsMultiSession) {
                        $sessionSupport = 'MultiSession';
                    }
                    else {
                        $sessionSupport = 'SingleSession';
                    }
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

                    if ($using:IsMultiSession) {
                        $brokerDeliveryGroupParams['SessionSupport'] = 'MultiSession';
                    }
                    else {
                        $brokerDeliveryGroupParams['SessionSupport'] = 'SingleSession';
                    }

                    $brokerDeliveryGroupParams['DesktopKind'] = $using:DesktopType;
                    Write-Verbose ($using:localizedData.AddingDeliveryGroup -f $using:Name);
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

        $scriptBlockParams = @($Name, $Description, $DeliveryType, $PublishedName, $ColorDepth, $Enabled, $IsMaintenanceMode, $IsRemotePC,
                                $IsSecureIca,$ShutdownDesktopsAfterUse,$TurnOnAddedMachine);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
            [ref] $null = Invoke-Command  @invokeCommandParams;
        }
        else {
            $invokeScriptBlock = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
            [ref] $null = InvokeScriptBlock -ScriptBlock $invokeScriptBlock;
        }

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

## Import the InvokeScriptBlock function into the current scope
. (Join-Path -Path (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common') -ChildPath 'InvokeScriptBlock.ps1');

Export-ModuleMember -Function *-TargetResource;
