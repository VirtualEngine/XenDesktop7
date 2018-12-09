Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7Database.Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,

        [Parameter(Mandatory)]
        [ValidateSet('Site','Logging','Monitor')]
        [System.String] $DataStore,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseName,

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    process {

        $targetResource = @{
            SiteName = $SiteName;
            DataStore = $DataStore;
            DatabaseServer = $DatabaseServer;
            DatabaseName = '';
        }

        #if ($PSBoundParameters.ContainsKey('Credential')) {

            if (TestMSSQLDatabase -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName -Credential $Credential) {
                $targetResource['DatabaseName'] = $DatabaseName;
            }
        #}
        #else {

        #    if (TestMSSQLDatabase -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName) {
        #        $targetResource['DatabaseName'] = $DatabaseName;
        #    }
        #}
        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,

        [Parameter(Mandatory)]
        [ValidateSet('Site','Logging','Monitor')]
        [System.String] $DataStore,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseName,

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    process {

        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($targetResource.DatabaseName -eq $DatabaseName) {

            Write-Verbose ($localizedData.DatabaseDoesExist -f $DataStore, $DatabaseName, $DatabaseServer);
            Write-Verbose ($localizedData.ResourceInDesiredState -f $DatabaseName);
            return $true;
        }
        else {

            Write-Verbose ($localizedData.DatabaseDoesNotExist -f $DataStore, $DatabaseName, $DatabaseServer);
            Write-Verbose ($localizedData.ResourceNotInDesiredState -f $DatabaseName);
            return $false;
        }

    } #end process
} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,

        [Parameter(Mandatory)]
        [ValidateSet('Site','Logging','Monitor')]
        [System.String] $DataStore,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseName,

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {

        AssertXDModule -Name 'Citrix.XenDesktop.Admin';

    } #end begin
    process {

        $scriptBlock = {

            Import-Module "$env:ProgramFiles\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1" -Verbose:$false;

            $newXDDatabaseParams = @{
                DatabaseServer = $using:DatabaseServer;
                DatabaseName = $using:DatabaseName;
                DataStore = $using:DataStore;
                SiteName = $using:SiteName;
            }

            if ($using:Credential) {
                $newXDDatabaseParams['DatabaseCredentials'] = $using:Credential;
            }

            Write-Verbose ($using:localizedData.CreatingXDDatabase -f $using:DataStore, $using:DatabaseName, $using:DatabaseServer);
            New-XDDatabase @newXDDatabaseParams;

        } #end scriptBlock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        $scriptBlockParams = @($SiteName, $DatabaseServer, $DataStore, $DatabaseName);
        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", $scriptBlockParams));
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
            [ref] $null = Invoke-Command @invokeCommandParams;
        }
        else {
            $invokeScriptBlock = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
            [ref] $null = InvokeScriptBlock -ScriptBlock $invokeScriptBlock;
        }

    } #end process
} #end function Set-TargetResource

#region Private Functions

function TestMSSQLDatabase {
    <#
    .SYNOPSIS
        Tests for the presence of a MS SQL Server database.
    .NOTES
        This function requires CredSSP to be enabled on the local machine to communicate with the MS SQL Server.
    #>
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseName,

        [Parameter()]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    process {

        $scriptBlock = {

            $sqlConnection = New-Object -TypeName 'System.Data.SqlClient.SqlConnection';
            $sqlConnection.ConnectionString = 'Server="{0}";Integrated Security=SSPI;' -f $using:DatabaseServer;
            $sqlCommand = $sqlConnection.CreateCommand();
            $sqlCommand.CommandText = "SELECT name FROM master.sys.databases WHERE name = N'$using:DatabaseName'";
            $sqlDataAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList $sqlCommand;
            $dataSet = New-Object -TypeName System.Data.DataSet;

            try {

                [ref] $null = $sqlDataAdapter.Fill($dataSet);
                if ($dataSet.Tables.Name) { return $true; } else { return $false; }
            }
            catch [System.Data.SqlClient.SqlException] {

                Write-Verbose $_;
                return $false;
            }
            finally {

                $sqlCommand.Dispose();
                $sqlConnection.Close();
            }

        } #end scriptblock

        $invokeCommandParams = @{
            ScriptBlock = $scriptBlock;
            ErrorAction = 'Stop';
        }

        Write-Verbose ($localizedData.InvokingScriptBlockWithParams -f [System.String]::Join("','", @($DatabaseServer, $DatabaseName)));
        if ($Credential) {
            AddInvokeScriptBlockCredentials -Hashtable $invokeCommandParams -Credential $Credential;
            return Invoke-Command @invokeCommandParams;
        }
        else {
            $invokeScriptBlock = [System.Management.Automation.ScriptBlock]::Create($scriptBlock.ToString().Replace('$using:','$'));
            return InvokeScriptBlock -ScriptBlock $invokeScriptBlock;
        }

    } #end process
} #end function TestMSSQLDatabase

#endregion Private Functions


$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;

## Import the XD7Common library functions
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

## Import the InvokeScriptBlock function into the current scope
. (Join-Path -Path (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common') -ChildPath 'InvokeScriptBlock.ps1');

Export-ModuleMember -Function *-TargetResource;
