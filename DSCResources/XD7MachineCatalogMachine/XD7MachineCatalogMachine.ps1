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
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerMachines = Get-BrokerMachine -CatalogName $using:Name | Select-Object -ExpandProperty DnsName;
            $targetResource = @{
                Name = $using:Name;
                Members = $brokerMachines;
            }
            return $targetResource;
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name)));
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
            if ($member.Contains('.')) {
                ## We have a FQDN and need to match based on NetBIOS name
                $member = $member.Split('.')[0];
            }
            if ($targetResource.Members -match "^$member\.") {
                ## Machine is in the list
                if ($Ensure -eq 'Absent') {
                    Write-Verbose ($localizedData.SurplusMachineCatalogMachine -f $member);
                    $targetResource['Ensure'] = 'Present';
                }
            }
            else {
                ## Machine is NOT in the list
                if ($Ensure -eq 'Present') {
                    Write-Verbose ($localizedData.MissingMachineCatalogMachine -f $member);
                    $targetResource['Ensure'] = 'Absent';
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
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerMachines = Get-BrokerMachine -CatalogName $using:Name | Select-Object -ExpandProperty DnsName;
            foreach ($member in $using:Members) {
                if ($member.Contains('.')) { ## We have a FQDN and need to match based on NetBIOS name
                    $member = $member.Split('.')[0];
                }
                if ($brokerMachines -match "^$member\.") { ## Machine is in the list
                    if ($using:Ensure -eq 'Absent') {
                        Write-Verbose ('Removing machine ''{0}'' from Citrix XenDesktop 7.x Machine Catalog ''{1}''.' -f $member, $using:Name);
                        Get-BrokerMachine -CatalogName $using:Name | Where-Object DNSName -match "^$member\." | Remove-BrokerMachine;
                    }
                }
                else { ## Machine is NOT in the list
                    if ($using:Ensure -eq 'Present') {
                        if (-not $brokerCatalog) {
                            $brokerCatalog = Get-BrokerCatalog -Name $using:Name;
                        }
                        Write-Verbose ('Adding machine ''{0}'' to Citrix XenDesktop 7.x Machine Catalog ''{1}''.' -f $member, $using:Name);
                        New-BrokerMachine -CatalogUid $brokerCatalog.Uid -MachineName $member -ErrorAction SilentlyContinue;
                    }
                }
            } #end foreach member
        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }
        if ($Credential) { AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential; }
        else { $invokeCommandParams['ScriptBlock'] = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$')); }
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Members, $Ensure)));
        Invoke-Command  @invokeCommandParams;
    } #end process
} #end function Set-TargetResource
