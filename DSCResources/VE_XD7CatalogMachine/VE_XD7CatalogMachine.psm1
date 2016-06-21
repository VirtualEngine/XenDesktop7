Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7CatalogMachine.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String[]] $Members,

        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    begin {
        AssertXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin;
    }
    process {

        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            $brokerMachines = Get-BrokerMachine -CatalogName $using:Name | Select-Object -ExpandProperty DnsName;
            $targetResource = @{
                Name = $using:Name;
                Members = $brokerMachines;
                Ensure = $using:Ensure;
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
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name)));
        return Invoke-Command  @invokeCommandParams;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String[]] $Members,

        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;
        if (TestXDMachineMembership -RequiredMembers $Members -ExistingMembers $targetResource.Members -Ensure $Ensure) {
            Write-Verbose ($localizedData.ResourcePropertyMismatch -f 'Members', $Members, $targetResource.Members);
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String[]] $Members,

        [Parameter()] [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    begin {
        AssertXDModule -Name 'Citrix.Broker.Admin.V2' -IsSnapin;
    }
    process {

        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2' -ErrorAction Stop;
            Import-Module "$env:ProgramFiles\WindowsPowerShell\Modules\XenDesktop7\DSCResources\VE_XD7Common\VE_XD7Common.psd1" -Verbose:$false;

            $brokerMachines = Get-BrokerMachine -CatalogName $using:Name;
            $brokerCatalog = Get-BrokerCatalog -Name $using:Name;
            foreach ($member in $using:Members) {
                $brokerMachine = ResolveXDBrokerMachine -MachineName $member -BrokerMachines $brokerMachines;
                if (($using:Ensure -eq 'Absent') -and ($brokerMachine.CatalogName -eq $using:Name)) {
                    Write-Verbose ($using:localizedData.RemovingMachineCatalogMachine -f $member, $using:Name);
                    $brokerMachine | Remove-BrokerMachine -CatalogName $using:Name -Force;
                }
                elseif (($using:Ensure -eq 'Present') -and ($brokerMachine.CatalogName -ne $using:Name)) {
                    [ref] $null = New-BrokerMachine -MachineName $member -CatalogUid $brokerCatalog.Uid -ErrorAction Stop;
                }
            } #end foreach member
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
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Members, $Ensure)));
        [ref] $null = Invoke-Command @invokeCommandParams;

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
