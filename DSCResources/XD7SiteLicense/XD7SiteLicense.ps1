Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $LicenseServer,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Int16] $LicenseServerPort = 27000,
        [Parameter()] [ValidateSet('PLT','ENT','APP')] [System.String] $LicenseEdition = 'PLT',
        [Parameter()] [ValidateSet('UserDevice','Concurrent')] [System.String] $LicenseModel = 'UserDevice',
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Configuration.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.Configuration.Admin.V2 module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            param (
                [System.String] $LicenseServer,
                [System.String] $LicenseServerPort,
                [System.String] $LicenseEdition,
                [System.String] $LicenseModel
            )
            $VerbosePreference = 'Continue';
            Add-PSSnapin -Name 'Citrix.Configuration.Admin.V2' -ErrorAction Stop;
            try {
                $xdSiteConfig = Get-ConfigSite;
            }
            catch { }
            $xdCurrentSite = @{
                LicenseServer = $xdSiteConfig.LicenseServerName;
                LicenseServerPort = $xdSiteConfig.LicenseServerPort;
                LicenseEdition = $xdSiteConfig.ProductEdition;
                LicenseModel = $xdSiteConfig.LicensingModel;
                Ensure = 'Present';
            };
            foreach ($parameterKey in $PSBoundParameters.Keys) {
                if ($xdCurrentSite[$parameterKey] -ne $PSBoundParameters[$parameterKey]) {
                    $xdCurrentSite['Ensure'] = 'Absent';
                    $PropertyMismatchMessage = 'Mismatch on property "{0}": "{1}" <> "{2}". Setting "Ensure" to "Absent".'
                    Write-Verbose ($PropertyMismatchMessage -f $parameterKey, $xdCurrentSite[$parameterKey], $PSBoundParameters[$parameterKey]);
                }
            }
            return [PSCustomObject] $xdCurrentSite;
        } #end scriptblock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($LicenseServer, $LicenseServerPort, $LicenseEdition, $LicenseModel);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        $targetResource = Invoke-Command @invokeCommandParams;
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $LicenseServer,
        [Parameter(Mandatory)] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Int16] $LicenseServerPort = 27000,
        [Parameter()] [ValidateSet('PLT','ENT','APP')] [System.String] $LicenseEdition = 'PLT',
        [Parameter()] [ValidateSet('UserDevice','Concurrent')] [System.String] $LicenseModel = 'UserDevice'
    )
    process {
        if ($Ensure -eq 'Absent') {
            ## Not supported and we will always return $true
            Write-Warning $localizedData.RemovingLicenseServerPropertiesWarning;
        }
        else {
            $targetResource = Get-TargetResource @PSBoundParameters;
            if (Compare-Object -ReferenceObject $targetResource -DifferenceObject $PSBoundParameters -Property LicenseServer, LicenseServerPort, LicenseEdition, LicenseModel, Ensure) {
                Write-Verbose $localizedData.ResourceNotInDesiredState;
                return $false;
            }
        }
        Write-Verbose $localizedData.ResourceInDesiredState;
        return $true;
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $LicenseServer,
        [Parameter(Mandatory)] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present',
        [Parameter()] [ValidateNotNull()] [System.Int16] $LicenseServerPort = 27000,
        [Parameter()] [ValidateSet('PLT','ENT','APP')] [System.String] $LicenseEdition = 'PLT',
        [Parameter()] [ValidateSet('UserDevice','Concurrent')] [System.String] $LicenseModel = 'UserDevice'
    )
    begin {
        if (-not (TestXDModule -Name 'Citrix.Configuration.Admin.V2' -IsSnapin)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.Configuration.Admin.V2 module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        Write-Verbose ($localizedData.SettingLicenseServerProperties -f $Server, $Port, $Edition);
        $scriptBlock = {
            param (
                [System.String] $LicenseServer,
                [System.String] $LicenseServerPort,
                [System.String] $LicenseEdition,
                [System.String] $LicenseModel
            )
            Add-PSSnapin -Name 'Citrix.Configuration.Admin.V2' -ErrorAction Stop;
            $setConfigSiteParams = @{
                LicenseServerName = $LicenseServer;
                LicenseServerPort = $LicenseServerPort;
                ProductEdition = $LicenseEdition;
                LicensingModel = $LicenseModel;
            }
            $xdConfigSite = Set-ConfigSite @setConfigSiteParams;
        } #end scriptBlock
        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($LicenseServer, $LicenseServerPort, $LicenseEdition, $LicenseModel);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        $invokeCommandResult = Invoke-Command @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
