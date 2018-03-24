Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7SiteLicense.Resources.psd1;


function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $LicenseServer,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNull()]
        [System.UInt16] $LicenseServerPort = 27000,

        [Parameter()]
        [ValidateSet('XDT','MPS')]
        [System.String] $LicenseProduct = 'XDT',

        [Parameter()]
        [ValidateSet('PLT','ENT','ADV')]
        [System.String] $LicenseEdition = 'PLT',

        [Parameter()]
        [ValidateSet('UserDevice','Concurrent')]
        [System.String] $LicenseModel = 'UserDevice',

        [Parameter()]
        [System.Boolean] $TrustLicenseServerCertificate = $true,

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {

        AssertXDModule -Name 'Citrix.Configuration.Admin.V2' -IsSnapin;

    }
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.Configuration.Admin.V2' -ErrorAction Stop;

            try {
                $xdSiteConfig = Get-ConfigSite;
            }
            catch { }

            $targetResource = @{
                LicenseServer = $xdSiteConfig.LicenseServerName;
                LicenseServerPort = $xdSiteConfig.LicenseServerPort;
                LicenseProduct = $xdSiteConfig.ProductCode;
                LicenseEdition = $xdSiteConfig.ProductEdition;
                LicenseModel = $xdSiteConfig.LicensingModel;
                TrustLicenseServerCertificate = !([System.String]::IsNullOrEmpty($xdSiteConfig.MetaDataMap.CertificateHash));
                Ensure = $using:Ensure;
            };

            return $targetResource;
        } #end scriptblock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        else {
            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
        }

        $scriptBlockParams = @($LicenseServer, $LicenseServerPort, $LicenseEdition, $LicenseModel);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));

        return Invoke-Command @invokeCommandParams;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $LicenseServer,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNull()]
        [System.UInt16] $LicenseServerPort = 27000,

        [Parameter()]
        [ValidateSet('XDT','MPS')]
        [System.String] $LicenseProduct = 'XDT',

        [Parameter()]
        [ValidateSet('PLT','ENT','ADV')]
        [System.String] $LicenseEdition = 'PLT',

        [Parameter()]
        [ValidateSet('UserDevice','Concurrent')]
        [System.String] $LicenseModel = 'UserDevice',

        [Parameter()]
        [System.Boolean] $TrustLicenseServerCertificate = $true,

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    process {

        if ($Ensure -eq 'Absent') {
            ## Not supported and we will always return $true
            Write-Warning $localizedData.RemovingLicenseServerPropertiesWarning;
        }
        else {

            $targetResource = Get-TargetResource @PSBoundParameters;
            $inCompliance = $true;

            foreach ($property in $PSBoundParameters.Keys) {

                if ($targetResource.ContainsKey($property)) {

                    $expected = $PSBoundParameters[$property];
                    $actual = $targetResource[$property];
                    if ($PSBoundParameters[$property] -is [System.String[]]) {

                        if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
                            Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, ($expected -join ','), ($actual -join ','));
                            $inCompliance = $false;
                        }
                    }
                    elseif ($expected -ne $actual) {

                        Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, $expected, $actual);
                        $inCompliance = $false;
                    }
                }
            }

            if ($inCompliance) {
                Write-Verbose ($localizedData.ResourceInDesiredState -f $DeliveryGroup);
            }
            else {
                Write-Verbose ($localizedData.ResourceNotInDesiredState -f $DeliveryGroup);
            }

            return $inCompliance;
        }

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $LicenseServer,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNull()]
        [System.UInt16] $LicenseServerPort = 27000,

        [Parameter()]
        [ValidateSet('XDT','MPS')]
        [System.String] $LicenseProduct = 'XDT',

        [Parameter()]
        [ValidateSet('PLT','ENT','ADV')]
        [System.String] $LicenseEdition = 'PLT',

        [Parameter()]
        [ValidateSet('UserDevice','Concurrent')]
        [System.String] $LicenseModel = 'UserDevice',

        [Parameter()]
        [System.Boolean] $TrustLicenseServerCertificate = $true,

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {

        AssertXDModule -Name 'Citrix.Configuration.Admin.V2' -IsSnapin;
        if ($TrustLicenseServerCertificate) {
            AssertXDModule -Name 'Citrix.Licensing.Admin.V1' -IsSnapin;
        }

    }
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.Configuration.Admin.V2' -ErrorAction Stop;

            $setConfigSiteParams = @{
                LicenseServerName = $using:LicenseServer;
                LicenseServerPort = $using:LicenseServerPort;
                ProductCode = $using:LicenseProduct;
                ProductEdition = $using:LicenseEdition;
                LicensingModel = $using:LicenseModel;
            }
            Write-Verbose ($using:localizedData.SettingLicenseServerProperties -f $using:LicenseServer, $using:LicenseServerPort, $using:LicenseEdition);
            Set-ConfigSite @setConfigSiteParams;

            if ($using:TrustLicenseServerCertificate) {
                Add-PSSnapin -Name 'Citrix.Licensing.Admin.V1' -ErrorAction Stop;
                $licenseServerCertificateHash = (Get-LicCertificate -AdminAddress $using:LicenseServer).CertHash;
                Set-ConfigSiteMetadata -Name 'CertificateHash' -Value $licenseServerCertificateHash;
            }

        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        else {
            $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
        }

        $scriptBlockParams = @($LicenseServer, $LicenseServerPort, $LicenseEdition, $LicenseModel);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));

        [ref] $null = Invoke-Command @invokeCommandParams;

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
