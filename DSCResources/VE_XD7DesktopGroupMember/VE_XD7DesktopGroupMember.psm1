Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7DesktopGroupMember.psd1;

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
    } #end begin
    process {

        $scriptBlock = {
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2';
            $targetResource = @{
                Name = $using:Name;
                Members = @();
                Ensure = 'Absent';
            }
            $targetResource['Members'] = Get-BrokerMachine -DesktopGroupName $using:Name | Select-Object -ExpandProperty DnsName;
            if ($targetResource['Members']) {
                $targetResource['Ensure'] = 'Present';
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
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($Name, $Members, $Ensure)));
        return Invoke-Command @invokeCommandParams;

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
            Add-PSSnapin -Name 'Citrix.Broker.Admin.V2';
            Import-Module "$env:ProgramFiles\WindowsPowerShell\Modules\XenDesktop7\DSCResources\VE_XD7Common\VE_XD7Common.psd1" -Verbose:$false;

            $brokerMachines = Get-BrokerMachine -DesktopGroupName $using:Name;
            foreach ($member in $using:Members) {
                $brokerMachine = ResolveXDBrokerMachine -MachineName $member -BrokerMachines $brokerMachines;
                if (($using:Ensure -eq 'Absent') -and ($brokerMachine.DesktopGroupName -eq $using:Name)) {
                    Write-Verbose ($using:localizedData.RemovingDeliveryGroupMachine -f $member, $using:Name);
                    $brokerMachine | Remove-BrokerMachine -DesktopGroup $using:Name -Force;
                }
                elseif (($using:Ensure -eq 'Present') -and ($brokerMachine.DesktopGroupName -ne $using:Name)) {
                    $brokerMachine = GetXDBrokerMachine -MachineName $member;
                    if ($null -eq $brokerMachine) {
                        ThrowInvalidOperationException -ErrorId 'MachineNotFound' -Message ($localizedData.MachineNotFoundError -f $member);
                    }
                    else {
                        Write-Verbose ($using:localizedData.AddingDeliveryGroupMachine -f $member, $using:Name);
                        $brokerMachine | Add-BrokerMachine -DesktopGroup $using:Name;
                    }
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
        $scriptBlockParams = @($Name, $Members, $Ensure);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        [ref] $null = Invoke-Command @invokeCommandParams;

    } #end process
} #end function Set-TargetResource


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
