Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7DesktopGroupApplication.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## Display name of the application
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## Path to the application executable
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## Desktop delivery group name
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DesktopGroupName,

        ## Desktop delivery group name
        [Parameter()]
        [ValidateSet('HostedOnDesktop','InstalledOnClient')]
        [System.String] $ApplicationType = 'HostedOnDesktop',

        ## Application executable arguments
        [Parameter()]
        [AllowNull()]
        [System.String] $Arguments,

        ## Working directory of the application executable
        [Parameter()]
        [AllowNull()]
        [System.String] $WorkingDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String] $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $DisplayName = $Name,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Visible = $true,

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
            $desktopGroup = Get-BrokerDesktopGroup -Name $using:DesktopGroupName -ErrorAction SilentlyContinue;
            $application = Get-BrokerApplication -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;

            $targetResource = @{
                Name = $using:Name;
                Path = $application.CommandLineExecutable;
                ApplicationType = if ($application) { $application.ApplicationType.ToString() };
                Arguments = $application.CommandLineArguments;
                WorkingDirectory = $application.WorkingDirectory;
                Description = $application.Description;
                DisplayName = $application.PublishedName;
                Enabled = $application.Enabled;
                Visible = $application.Visible;
                Ensure = if ($application) { 'Present'} else { 'Absent' };
            }

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

        $scriptBlockParams = @($Name);
        Write-Verbose -Message ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        $targetResource = Invoke-Command  @invokeCommandParams;

        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        ## Display name of the application
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## Path to the application executable
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## Desktop delivery group name
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DesktopGroupName,

        ## Desktop delivery group name
        [Parameter()]
        [ValidateSet('HostedOnDesktop','InstalledOnClient')]
        [System.String] $ApplicationType = 'HostedOnDesktop',

        ## Application executable arguments
        [Parameter()]
        [AllowNull()]
        [System.String] $Arguments,

        ## Working directory of the application executable
        [Parameter()]
        [AllowNull()]
        [System.String] $WorkingDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String] $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $DisplayName = $Name,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Visible = $true,

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
        $inDesiredState = $true;

        foreach ($property in $targetResource.Keys) {

            if ($property -eq 'ApplicationType') {
                ## If we don't have an application, the ApplicationType won't be correct!
                if (($targetResource.Ensure -eq 'Present') -and ($ApplicationType -ne $targetResource.ApplicationType)) {

                    $errorMessage = $localizedData.ImmutablePropertyError -f 'ApplicationType';
                    ThrowInvalidOperationException -ErrorId 'ImmutablePropertyError' -ErrorMessage $errorMessage;
                }
            }
            elseif ($PSBoundParameters.ContainsKey($property) -and ($targetResource.$property -ne $PSBoundParameters.$property)) {

                Write-Verbose -Message ($localizedData.ApplicationPropertyMismatch -f $property, $PSBoundParameters.$property, $targetResource.$property);
                $inDesiredState = $false;
            }
        }
        if ($inDesiredState) {

            Write-Verbose -Message ($localizedData.ResourceInDesiredState -f $Name);
            return $true;
        }
        else {

            Write-Verbose -Message ($localizedData.ResourceNotInDesiredState -f $Name);
            return $false;
        }

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        ## Display name of the application
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## Path to the application executable
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## Desktop delivery group name
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DesktopGroupName,

        ## Desktop delivery group name
        [Parameter()]
        [ValidateSet('HostedOnDesktop','InstalledOnClient')]
        [System.String] $ApplicationType = 'HostedOnDesktop',

        ## Application executable arguments
        [Parameter()]
        [AllowNull()]
        [System.String] $Arguments,

        ## Working directory of the application executable
        [Parameter()]
        [AllowNull()]
        [System.String] $WorkingDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String] $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $DisplayName = $Name,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Enabled = $true,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $Visible = $true,

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

        AssertXDModule -Name 'Citrix.Common.Commands','Citrix.Broker.Admin.V2' -IsSnapin;

    }
    process {

        $scriptBlock = {

            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            Add-PSSnapin -Name 'Citrix.Common.Commands' -ErrorAction Stop;
            $desktopGroup = Get-BrokerDesktopGroup -Name $using:DesktopGroupName;
            $application = Get-BrokerApplication -Name $using:Name -DesktopGroupUid $desktopGroup.Uid -ErrorAction SilentlyContinue;

            $applicationParams = @{
                CommandLineExecutable = $using:Path;
            }

            if ($null -ne $using:Arguments) {
                $applicationParams['CommandLineArguments'] = $using:Arguments;
            }

            if ($null -ne $using:WorkingDirectory) {
                $applicationParams['WorkingDirectory'] = $using:WorkingDirectory;
            }

            if ($null -ne $using:Description) {
                $applicationParams['Description'] = $using:Description;
            }

            if ($null -ne $using:DisplayName) {
                $applicationParams['BrowserName'] = $using:DisplayName;
            }

            if ($null -ne $using:Enabled) {
                $applicationParams['Enabled'] = $using:Enabled;
            }

            if ($null -ne $using:Visible) {
                $applicationParams['Visible'] = $using:Visible;
            }

            if ($application) {

                if ($using:Ensure -eq 'Present') {

                    Write-Verbose -Message ($using:localizedData.UpdatingApplication -f $using:Name);
                    Set-BrokerApplication -InputObject $application @applicationParams;
                }
                else {

                    Write-Verbose -Message ($using:localizedData.RemovingApplication -f $using:Name);
                    Remove-BrokerApplication -InputObject $application;
                }

            }
            else {

                if ($using:Ensure -eq 'Present') {

                    Write-Verbose -Message ($using:localizedData.AddingApplicationIcon -f $using:Name);
                    try {

                        $icon = Get-CTXIcon -FileName $using:Path -ErrorAction Stop | Select-Object -First 1 | New-BrokerIcon;
                        $applicationParams['IconUid'] = $icon.Uid;
                    }
                    catch {
                        Write-Warning -Message ($using:localizedData.CannotLocateIconWarning -f $using:Path);
                    }

                    $applicationParams['Name'] = $using:Name;
                    $applicationParams['ApplicationType'] = $using:ApplicationType;
                    $applicationParams['DesktopGroup'] = $desktopGroup;
                    Write-Verbose -Message ($using:localizedData.AddingApplication -f $using:Name);

                    [ref] $null = New-BrokerApplication @applicationParams;
                }

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

        $scriptBlockParams = @($Name, $Path, $Arguments, $WorkingDirectory, $Description, $DisplayName, $Enabled, $Visible);
        Write-Verbose -Message ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));

        [ref] $null = Invoke-Command @invokeCommandParams;

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
