#region Private Functions
<#
function InvokeScriptBlock {
    <#
    .SYNOPSIS
        Executes a scriptblock in a separate Powershell instance, under different credentials.
    #> <#
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNull()] [SYstem.Management.Automation.ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory)] [ValidateNotNull()] [System.Management.Automation.PSCredential] $Credential,
        [Parameter()] [AllowNull()] [System.Object[]] $ArgumentList
    )
    process {
        if ($ArgumentList) {
            $command = '& {{ {0} }} "{1}"' -f $command, [System.String]::Join('" "', $argumentList);
        }
        else {
            $command = '& {{ {0} }}' -f $ScriptBlock;
        }
        #$encodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptBlock));
        $powershellExeArguments = @(
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'ByPass',
            #'-EncodedCommand',
            #$encodedCommand,
            #$('"{0}"' -f [System.String]::Join('" "', $argumentList))
            '-Command',
            $command
        );
        $processResult = StartWaitProcess -Credential $Credential -FilePath "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $powershellExeArguments;
        return $processResult;
    } #end process
} #end function InvokeScriptBlock #>


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

function FindXDModule {
    <#
    .SYNOPSIS
        Locates a module's manifest (.psd1) file.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Name = 'Citrix.XenDesktop.Admin',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Path = 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1'
    )
    process {
        $module = Get-ChildItem -Path $Path -Include "$Name.psd1" -File -Recurse;
        return $module.FullName;
    } #end process
} #end function FindModule

function TestXDModule {
    <#
    .SYNOPSIS
        Tests whether Powershell modules or Snapin are available/registered.
    #>
    [CmdletBinding()]
    param (
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Name = 'Citrix.XenDesktop.Admin',
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Path = 'C:\Program Files\Citrix\XenDesktopPoshSdk\Module\Citrix.XenDesktop.Admin.V1'
    )
    process {
        if (FindXDModule @PSBoundParameters) { return $true; }
        else { return $false; }
    } #end process
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