Import-LocalizedData -BindingVariable localizedData -FileName Resources.psd1;

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $Name,
        
        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    process {
        $targetResource = @{
            Name = '';
            Ensure = $Ensure;
        }
        $listOfDDCs = GetRegistryValue -Key 'HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent' -Name 'ListOfDDCs';
        if ($listOfDDCs) {
            $targetResource['Name'] = $listOfDDCs.Split(' ');
        }
        return $targetResource;
    } #end process
} #end Get-TargetResource

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $Name,
        
        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    process {
        $targetResource = Get-TargetResource @PSBoundParameters;
        if ($Ensure -eq 'Present') {
            ## Ensure that the controller is in the list
            if ($targetResource.Name -notcontains $Name) {
                Write-Verbose ($localizedData.MissingDeliveryController -f $Name);
                $targetResource['Ensure'] = 'Absent';
            }
        }
        else {
            ## Ensure that the controller is NOT in the list
            if ($targetResource.Name -contains $Name) {
                Write-Verbose ($localizedData.AdditionalDeliveryController -f $Name);
                $targetResource['Ensure'] = 'Present';
            }
        }
        if ($targetResource.Ensure -eq $Ensure) {
            Write-Verbose $localizedData.ResourceInDesiredState;
            return $true;
        }
        else {
            Write-Verbose $localizedData.ResourceNotInDesiredState;
            return $false;
        }
    } #end process
} #end Test-TargetResource

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $Name,
        
        [Parameter()] [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )
    process {
        $listOfDDCs = GetRegistryValue -Key 'HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent' -Name 'ListOfDDCs';
        $ddcs = New-Object -TypeName 'System.Collections.ArrayList' -ArgumentList @();
        if (-not [System.String]::IsNullOrEmpty($listOfDDCs)) {
            $ddcs.AddRange($listOfDDCs.Split(' '));
        }

        ## Ensure that the controller is in the list
        if ($Ensure -eq 'Present') {
            Write-Verbose ($localizedData.AddingDeliveryController -f $Name);
            [ref] $null = $ddcs.Add($Name);
        }
        ## Ensure that the controller is NOT in the list
        if ($Ensure -eq 'Absent') {
            Write-Verbose ($localizedData.RemovingDeliveryController -f $Name);    
            [ref] $null = $ddcs.Remove($Name);
        }
        $listOfDDCs = [System.String]::Join(' ', $ddcs.ToArray());
        Write-Verbose ($localizedData.SettingRegSZValue -f 'ListOfDDCs', $listOfDDCs);
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent' -Name 'ListOfDDCs' -Value $listOfDDCs;
        Write-Verbose ($localizedData.RestartingService -f 'BrokerAgent');
        Restart-Service -Name 'BrokerAgent' -Force;
    } #end process
} #end Set-TargetResource
