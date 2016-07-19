Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7SiteConfig.Resources.psd1;


function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## Single instance key
        [Parameter(Mandatory)]
        [ValidateSet('Yes')]
        [System.String] $IsSingleInstance,

        ## The XML Service trust settings
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $TrustRequestsSentToTheXmlServicePort,

        ## The default SecureICA usage requirements for new desktop groups
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $SecureIcaRequired,

        ## The setting to configure whether numeric IP address or the DNS name to be present in the ICA file
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $DnsResolutionEnabled,

        ## The objectGUID property identifying the base OU in Active Directory used for desktop registrations
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $BaseOU,

        ## The indicator for connection leasing active
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $ConnectionLeasingEnabled,

        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {

        AssertXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapIn;

    } #end begin
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;

            try {
                $brokerSite = Get-BrokerSite;
            }
            catch { }

            $targetResource = @{
                TrustRequestsSentToTheXmlServicePort = $brokerSite.TrustRequestsSentToTheXmlServicePort;
                SecureIcaRequired = $brokerSite.SecureIcaRequired;
                DnsResolutionEnabled = $brokerSite.DnsResolutionEnabled;
                BaseOU = if ($brokerSite.BaseOU) { $brokerSite.BaseOU.ToString(); }
                ConnectionLeasingEnabled = $brokerSite.ConnectionLeasingEnabled;
                SiteName = $brokerSite.Name;
            };

            return $targetResource;

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

        Write-Verbose $localizedData.InvokingScriptBlock;
        return Invoke-Command @invokeCommandParams;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        ## Single instance key
        [Parameter(Mandatory)]
        [ValidateSet('Yes')]
        [System.String] $IsSingleInstance,

        ## The XML Service trust settings
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $TrustRequestsSentToTheXmlServicePort,

        ## The default SecureICA usage requirements for new desktop groups
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $SecureIcaRequired,

        ## The setting to configure whether numeric IP address or the DNS name to be present in the ICA file
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $DnsResolutionEnabled,

        ## The objectGUID property identifying the base OU in Active Directory used for desktop registrations
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $BaseOU,

        ## The indicator for connection leasing active
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $ConnectionLeasingEnabled,

        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;

        $parameters = @(
            'TrustRequestsSentToTheXmlServicePort',
            'SecureIcaRequired',
            'DnsResolutionEnabled',
            'BaseOU',
            'ConnectionLeasingEnabled'
        )
        $inCompliance = $true;
        foreach ($parameter in $parameters) {

            if ($PSBoundParameters.ContainsKey($parameter)) {

                $expectedValue = $PSBoundParameters[$parameter];
                $actualValue = $targetResource[$parameter];

                if ($expectedValue -ne $actualValue) {
                    Write-Verbose ($localizedData.ResourcePropertyMismatch -f $parameter, $expectedValue, $actualValue);
                    $inCompliance = $false;

                }
            }
        }

        if ($inCompliance) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f 'SiteConfig');
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f 'SiteConfig');
        }
        return $inCompliance;

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        ## Single instance key
        [Parameter(Mandatory)]
        [ValidateSet('Yes')]
        [System.String] $IsSingleInstance,

        ## The XML Service trust settings
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $TrustRequestsSentToTheXmlServicePort,

        ## The default SecureICA usage requirements for new desktop groups
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $SecureIcaRequired,

        ## The setting to configure whether numeric IP address or the DNS name to be present in the ICA file
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $DnsResolutionEnabled,

        ## The objectGUID property identifying the base OU in Active Directory used for desktop registrations
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $BaseOU,

        ## The indicator for connection leasing active
        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.Boolean] $ConnectionLeasingEnabled,

        [Parameter()] [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {

        AssertXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapIn;

    } #end begin
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;

            $setBrokerSiteParams = @{ };

            if (($using:PSBoundParameters).ContainsKey('TrustRequestsSentToTheXmlServicePort')) {
                $setBrokerSiteParams['TrustRequestsSentToTheXmlServicePort'] = $using:TrustRequestsSentToTheXmlServicePort;
            }

            if (($using:PSBoundParameters).ContainsKey('SecureIcaRequired')) {
                $setBrokerSiteParams['SecureIcaRequired'] = $using:SecureIcaRequired;
            }

            if (($using:PSBoundParameters).ContainsKey('DnsResolutionEnabled')) {
                $setBrokerSiteParams['DnsResolutionEnabled'] = $using:DnsResolutionEnabled;
            }

            if (($using:PSBoundParameters).ContainsKey('BaseOU')) {
                $setBrokerSiteParams['BaseOU'] = $using:BaseOU;
            }

            if (($using:PSBoundParameters).ContainsKey('ConnectionLeasingEnabled')) {
                $setBrokerSiteParams['ConnectionLeasingEnabled'] = $using:ConnectionLeasingEnabled;
            }

            if ($setBrokerSiteParams.Keys.Count -gt 0) {
                $brokerSite = Set-BrokerSite @setBrokerSiteParams;
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

        $parameters = @(
            'TrustRequestsSentToTheXmlServicePort',
            'SecureIcaRequired',
            'DnsResolutionEnabled',
            'BaseOU',
            'ConnectionLeasingEnabled'
        )
        foreach ($parameter in $parameters) {
            if ($PSBoundParameters.ContainsKey($parameter)) {
                $scriptBlockParam = "{0}' = '{1}" -f $parameter, $PSBoundParameters[$parameter];
                Write-Verbose ($localizedData.InvokingScriptBlockWithParam -f $scriptBlockParam);
            }
        }

        [ref] $null = Invoke-Command  @invokeCommandParams;

    } #end process
} #end function Test-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
