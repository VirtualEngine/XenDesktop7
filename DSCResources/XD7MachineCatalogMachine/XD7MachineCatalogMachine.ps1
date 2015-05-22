Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
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
            $brokerMachines = Get-BrokerMachine -CatalogName $Name | Select-Object -ExpandProperty DnsName;
            $targetResource = @{
                Name = $Name;
                Members = $brokerMachines;
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
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        foreach ($member in $Members) {
            if ($Ensure -eq 'Present') {
                ## Ensure that the controller is in the list
                if (-not $member.Contains('.')) {
                    ## Machines are stored by their FQDN but we don't have a FQDN, check by NetBIOS name
                    if ($targetResource.Members -notlike "$member*") {
                        Write-Verbose ($localizedData.MissingMachineCatalogMachine -f $member);
                        $targetResource['Ensure'] = 'Absent';
                    }
                }
                else {
                    ## Check for match by FQDN
                    if ($targetResource.Members -notcontains $member) {
                        Write-Verbose ($localizedData.MissingMachineCatalogMachine -f $member);
                        $targetResource['Ensure'] = 'Absent';
                    }
                }
            }
            else {
                ## Ensure that the controller is NOT in the list
                if (-not $member.Contains('.')) {
                    ## Machines are stored by their FQDN but we don't have a FQDN, check by NetBIOS name
                    if ($targetResource.Members -like "$member*") {
                        Write-Verbose ($localizedData.SurplusMachineCatalogMachine -f $member);
                        $targetResource['Ensure'] = 'Present';
                    }
                }
                else {
                    ## Check for match by FQDN
                    if ($targetResource.Members -contains $member) {
                        Write-Verbose ($localizedData.SurplusMachineCatalogMachine -f $member);
                        $targetResource['Ensure'] = 'Present';
                    }
                }
            }
        } #end foreach member
        if ($Ensure -eq $targetResource['Ensure']) {
            Write-Verbose ($localizedData.ResourceInDesiredState -f $Name);
            return $true;
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $Name);
            return $false;
        }
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $Name,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String[]] $Members,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
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
                [System.String[]] $Members,
                [System.String] $Ensure
            )
            data localizedData {
                ConvertFrom-StringData @'
                    AddingMachineCatalogMachine = Adding machine '{0}' to Citrix XenDesktop 7.x Machine Catalog '{1}'.
                    RemovingMachineCatalogMachine = Removing machine '{0}' from Citrix XenDesktop 7.x Machine Catalog '{1}'.
'@
            }
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerMachines = Get-BrokerMachine -CatalogName $Name | Select-Object -ExpandProperty DnsName;
            foreach ($member in $Members) {
                if ($Ensure -eq 'Present' -and $brokerMachines -notcontains $member) {
                    if ($member.Contains('.')) { $member = $member.Split('.')[0]; }
                    if (-not $brokerCatalog) {
                        $brokerCatalog = Get-BrokerCatalog -Name $Name;
                    }
                    Write-Verbose ($localizedData.AddingMachineCatalogMachine -f $member, $Name);
                    New-BrokerMachine -CatalogUid $brokerCatalog.Uid -MachineName $member -ErrorAction SilentlyContinue;
                }
                elseif ($Ensure -eq 'Absent' -and $brokerMachines -contains $member) {
                    Write-Verbose ($localizedData.RemovingMachineCatalogMachine -f $member, $Name);
                    Get-BrokerMachine -CatalogName $Name | Where-Object DNSName -eq $member | Remove-BrokerMachine;
                }
            } #end foreach member
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ArgumentList = @($Name, $Members, $Ensure);
            ErrorAction = 'Stop';
        }
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
        }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Set-TargetResource