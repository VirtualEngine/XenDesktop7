Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateSet('Site','Logging','Monitor')] [System.String] $DataStore,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseName,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $targetResource = @{
            SiteName = $SiteName;
            DataStore = $DataStore;
            DatabaseServer = $DatabaseServer;
            Credential = $Credential;
            DatabaseName = '';
        }
        if (TestMSSQLDatabase -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName -Credential $Credential) {
            $targetResource['DatabaseName'] = $DatabaseName;
        }
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateSet('Site','Logging','Monitor')] [System.String] $DataStore,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseName,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($targetResource.DatabaseName -eq $DatabaseName) {
            Write-Verbose ($localizedData.DatabaseDoesExist -f $DataStore, $DatabaseName, $DatabaseServer);
            return $true;
        }
        else {
            Write-Verbose ($localizedData.DatabaseDoesNotExist -f $DataStore, $DatabaseName, $DatabaseServer);
            return $false;
        }
    } #end process
} #end function Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateSet('Site','Logging','Monitor')] [System.String] $DataStore,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseName,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestXDModule)) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    } #end begin
    process {
        Write-Verbose ($localizedData.CreatingXDDatabase -f $DataStore, $DatabaseName, $DatabaseServer);
        ## The New-XDDatabase cmdlet needs to be run with domain credentials :(
        $scriptBlock = {
            param (
                $DatabaseCredentials,
                $SiteName,
                $DatabaseServer,
                $DataStore,
                $DatabaseName
            )
            Import-Module 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1\Citrix.XenDesktop.Admin\Citrix.XenDesktop.Admin.psd1';
            New-XDDatabase -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName -DataStore $DataStore -SiteName $SiteName -DatabaseCredentials $DatabaseCredentials;
        } #end scriptBlock
        $invokeCommandParams = @{
            ComputerName = $env:COMPUTERNAME;
            Credential = $Credential;
            ScriptBlock = $scriptBlock;
            ArgumentList = @($Credential, $SiteName, $DatabaseServer, $DataStore, $DatabaseName);
        }
        Write-Verbose ($localizedData.InvokingScriptBlock -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        $invokeCommandResult = Invoke-Command @invokeCommandParams;
    } #end process
} #end function Test-TargetResource

#region Private Functions

function TestMSSQLDatabase {
    <#
    .SYNOPSIS
        Tests for the presence of a MS SQL Server database.
    .NOTES
        This function requires CredSSP to be enabled on the local machine to communicate with the MS SQL Server.
    #>
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseName,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $scriptBlock = {
            param (
                [System.String] $DatabaseServer,
                [System.String] $DatabaseName
            )
            $sqlConnection = New-Object -TypeName 'System.Data.SqlClient.SqlConnection';
            $sqlConnection.ConnectionString = 'Server="{0}";Integrated Security=SSPI;' -f $DatabaseServer;
            $sqlCommand = $sqlConnection.CreateCommand();
            $sqlCommand.CommandText = "SELECT name FROM master.sys.databases WHERE name = N'$DatabaseName'";
            $sqlDataAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList $sqlCommand;
            $dataSet = New-Object -TypeName System.Data.DataSet;
            try {
                [ref]$null = $sqlDataAdapter.Fill($dataSet);
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
            ComputerName = $env:COMPUTERNAME;
            Credential = $Credential;
            Authentication = 'Credssp';
            ScriptBlock = $scriptBlock;
            ArgumentList = @($DatabaseServer, $DatabaseName);
            ErrorAction = 'Stop';
        }
        Write-Verbose ('Invoking script block with ''{0}'' parameters.' -f [System.String]::Join("','", $invokeCommandParams['ArgumentList']));
        return Invoke-Command  @invokeCommandParams;
    } #end process
} #end function TestMSSQLDatabase

#endregion Private Functions
