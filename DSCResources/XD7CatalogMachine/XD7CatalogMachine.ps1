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
            ThrowInvalidProgramException -ErrorId 'Citrix.Broker.Admin.V2' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerMachines = Get-BrokerMachine -CatalogName $using:Name | Select-Object -ExpandProperty DnsName;
            $targetResource = @{
                Name = $using:Name;
                Members = $brokerMachines;
                Ensure = $using:Ensure;
                Credential = $using:Credential;
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
        return Invoke-Command  @invokeCommandParams;
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
        if (TestXDMachineMembership -RequiredMembers $Members -ExistingMembers $targetResource.Members -Ensure $Ensure) {
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
            ThrowInvalidProgramException -ErrorId 'Citrix.Broker.Admin.V2' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            Import-Module "$env:ProgramFiles\WindowsPowerShell\Modules\CitrixXenDesktop7\DSCResources\XD7Common\XD7Common.psd1" -Verbose:$false;

            $brokerMachines = Get-BrokerMachine -CatalogName $using:Name;
            $brokerCatalog = Get-BrokerCatalog -Name $using:Name;
            foreach ($member in $using:Members) {
                $brokerMachine = ResolveXDBrokerMachine -MachineName $member -BrokerMachines $brokerMachines;
                if (($using:Ensure -eq 'Absent') -and ($brokerMachine.CatalogName -eq $using:Name)) {
                    Write-Verbose ($using:localizedData.RemovingMachineCatalogMachine -f $member, $using:Name);
                    $brokerMachine | Remove-BrokerMachine -CatalogName $using:Name -Force;
                }
                elseif (($using:Ensure -eq 'Present') -and ($brokerMachine.CatalogName -ne $using:Name)) {
                    if ($brokerMachine -eq $null) {
                        Write-Verbose ($using:localizedData.AddingMachineCatalogMachine -f $member, $using:Name);
                        New-BrokerMachine -MachineName $member -CatalogUid $brokerCatalog.Uid -ErrorAction Stop;
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
