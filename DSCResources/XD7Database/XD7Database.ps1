Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateSet('Site','Logging','Monitor')] [System.String] $DataStore,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseName,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $targetResource = @{
            SiteName = $SiteName;
            DataStore = $DataStore;
            DatabaseServer = $DatabaseServer;
            Credential = $Credential;
            DatabaseName = '';
        }
        if (TestMSSqlDatabase -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName -Credential $Credential) {
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
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($targetResource.DatabaseName -eq $DatabaseName) {
            Write-Verbose ($localizedData.DatabaseDoesExist -f $DataStore, $DatabaseName, $DatabaseServer);
            return $false;
        }
        else {
            Write-Verbose ($localizedData.DatabaseDoesNotExist -f $DataStore, $DatabaseName, $DatabaseServer);
            return $true;
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
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        if (-not (TestModule -Name 'Citrix.XenDesktop.Admin')) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $newXDDatabaseParams = @{
            SiteName = $SiteName;
            DatabaseServer = $DatabaseServer;
            DataStore = $DataStore;
            DatabaseName = $DatabaseName;
        }
        if ($Credential) {
            $newXDDatabaseParams['DatabaseCredentials'] = $Credential;
        }
        Write-Verbose ($localizedData.CreatingXDDatabase -f $DataStore, $DatabaseName, $DatabaseServer);
        $xdDatabase = New-XDDatabase @newXDDatabaseParams;
    } #end process
} #end function Test-TargetResource

#region Private Functions

function TestMSSqlDatabase {
    <#
    .SYNOPSIS
        Tests for the presence of a MS SQL Server database.
    #>
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseServer,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $DatabaseName,
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential
    )

    $scriptBlock = {
        $sqlConnection = New-Object -TypeName 'System.Data.SqlClient.SqlConnection';
        $sqlConnection.ConnectionString = 'Server="{0}";Integrated Security=SSPI;' -f $args[0];
        $sqlCommand = $sqlConnection.CreateCommand();
        $sqlCommand.CommandText = "SELECT name FROM master.sys.databases WHERE name = N'$($args[1])'";
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

    if ($Credential) {
        return Start-Job -ScriptBlock $scriptBlock -ArgumentList $DatabaseServer, $DatabaseName -Credential $Credential | Receive-Job -Wait;
    }
    else {
        return Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $DatabaseServer, $DatabaseName;
    }    
} #end function TestMSSQLDatabase

#endregion Private Functions
