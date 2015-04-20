#region Private Functions

function StartWaitProcess {
    <#
    .SYNOPSIS
        Starts and waits for a process to exit.
    .NOTES
        This is an internal function and shouldn't be called from outside.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Int32])]
    param (
        # Path to process to start.
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $FilePath,
        # Arguments (if any) to apply to the process.
        [Parameter()] [AllowNull()] [System.String[]] $ArgumentList,
        # Credential to start the process as.
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential,
        # Working directory
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $WorkingDirectory = (Split-Path -Path $FilePath -Parent)
    )
    process {
        $startProcessParams = @{
            FilePath = $FilePath;
            WorkingDirectory = $WorkingDirectory;
            NoNewWindow = $true;
            PassThru = $true;
        };
        $displayParams = '<None>';
        if ($ArgumentList) {
            $displayParams = [System.String]::Join(' ', $ArgumentList);
            $startProcessParams['ArgumentList'] = $ArgumentList;
        }
        Write-Verbose ($localizedData.StartingProcess -f $FilePath, $displayParams);
        if ($Credential) {
            Write-Verbose ($localizedData.StartingProcessAs -f $Credential.UserName);
            $startProcessParams['Credential'] = $Credential;
        }
        if ($PSCmdlet.ShouldProcess($FilePath, 'Start Process')) {
            $process = Start-Process @startProcessParams -ErrorAction Stop;
        }
        if ($PSCmdlet.ShouldProcess($FilePath, 'Wait Process')) {
            Write-Verbose ($localizedData.ProcessLaunched -f $process.Id);
            Write-Verbose ($localizedData.WaitingForProcessToExit -f $process.Id);
            $process.WaitForExit();
            $exitCode = [System.Convert]::ToInt32($process.ExitCode);
            Write-Verbose ($localizedData.ProcessExited -f $process.Id, $exitCode);
        }
        return $exitCode;
    } #end process
} #end function StartWaitProcess

function TestModule {
    <#
    .SYNOPSIS
        Tests whether Powershell modules or Snapin are available/registered.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)] [ValidateNotNullOrEmpty()] [System.String[]] $Name,
        [Parameter()] [System.Management.Automation.SwitchParameter] $IsSnapin
    )
    begin {
        [System.Boolean] $allModulesFound = $true;
    }
    process {
        foreach ($module in $Name) {
            if ($IsSnapin) {
                $powershellModule = Get-PSSnapin -Name $module -Registered -ErrorAction SilentlyContinue;
            }
            else {
                $powershellModule = Get-Module -Name $module -ErrorAction SilentlyContinue;
            }
            if ($powershellModule -eq $null) {
                $allModulesFound = $false;
            }
        }
    } #end process
    end {
        return $allModulesFound;
    }
} #end TestModule

function ThrowInvalidProgramException {
    <#
    .SYNOPSIS
        Throws terminating error of category NotInstalled with specified errorId and errorMessage.
    #>
    param(
        [Parameter(Mandatory)] [System.String] $ErrorId,
        [Parameter(Mandatory)] [System.String] $ErrorMessage
    )
    $errorCategory = [System.Management.Automation.ErrorCategory]::NotInstalled;
    $exception = New-Object -TypeName 'System.InvalidProgramException' -ArgumentList $ErrorMessage;
    $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $exception, $ErrorId, $errorCategory, $null;
    throw $errorRecord;
} #end function ThrowInvalidProgramException

#endregion Private Functions