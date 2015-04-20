function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $ControllerName, ## Existing controller used to join/remove the site.
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential, ## Database credentials used to join/remove the controller to/from the site.
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
    )
    begin {
        if (-not (TestModule -Name 'Citrix.XenDesktop.Admin')) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $xdSite = Get-XDSite -AdminAddress $ControllerName;
        $targetResource = @{
            SiteName = $xdSite.Name;
            Controller = $ControllerName;
            Credential = $Credential;
            Ensure = 'Absent';
        }
        foreach ($controller in $xdSite.Controllers) {
            $hostname = [System.Net.Dns]::GetHostName();
            if ($controller.DnsName -eq $hostname -or $controller.MachineName -match "$hostname`$") {
                $targetResource['Ensure'] = 'Present';
            }
        }
        return $targetResource;
    } #end process
} #end function Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $ControllerName, ## Existing controller used to join/remove the site
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential, ## Database credentials used to join/remove the controller to/from the site.
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
    )
    process {
        $xdSite = Get-TargetResource @PSBoundParameters;
        if ($xdSite.SiteName -eq $SiteName -and $xdSite.Ensure -eq $Ensure) {
            return $false;
        }
        return $true;
    } #end process
} #end function Test-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $SiteName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.String] $ControllerName, ## Existing controller used to join the site
        [Parameter()] [AllowNull()] [System.Management.Automation.PSCredential] $Credential, ## Database credentials used to join/remove the controller to/from the site.
        [Parameter()] [ValidateSet('Present','Absent')] [System.String] $Ensure = 'Present'
    )
    begin {
        if (-not (TestModule -Name 'Citrix.XenDesktop.Admin')) {
            ThrowInvalidProgramException -ErrorId 'Citrix.XenDesktop.Admin module not found.' -ErrorMessage $localizedData.XenDesktopSDKNotFoundError;
        }
    }
    process {
        $controllerParams = @{ }
        if ($Credential) { $controllerParams['DatabaseCredentials'] = $Credential; }
        if ($Ensure -eq 'Present') {
            $controllerParams['SiteControllerAddress'] = $ControllerName; 
            $controller = Add-XDController @controllerParams;
        }
        else {
            $controllerParams['AdminAddress'] = $ControllerName;
            $controllerParams['ControllerName'] = [System.Net.Dns]::GetHostName();
            $controller = Remove-XDController @controllerParams; }
    } #end process
} #end function Test-TargetResource
