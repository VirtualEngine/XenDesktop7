Import-LocalizedData -BindingVariable localizedData -FileName VE_XD7StoreFrontStore.Resources.psd1;

function Get-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Explicit','Anonymous')]
        [System.String]
        $AuthType
    )
    begin
    {
        AssertModule -Name Citrix.StoreFront
    }
    process
    {
        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false;

        $StoreService = Get-STFStoreService -Verbose | Where-Object { $_.FriendlyName -eq $StoreName };

        $targetResource = @{
            StoreName = $StoreService.FriendlyName
            AuthType = if ($StoreService.Service.Anonymous) { 'Anonymous' } else { 'Explicit' }
            AuthVirtualPath = $StoreService.AuthenticationServiceVirtualPath
            StoreVirtualPath = $StoreService.VirtualPath
            SiteId = $StoreService.SiteId
            LockedDown = $StoreService.Service.LockedDown
            AllowSessionReconnect = $StoreService.Service.AllowSessionReconnect
            SubstituteDesktopImage = $StoreService.Service.SubstituteDesktopImage
        };

        return $targetResource;

    } #end process
} #end function Get-TargetResource


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType,

        [Parameter()]
        [System.String]
        $AuthVirtualPath = "/Citrix/Authentication",

        [Parameter()]
        [System.String]
        $StoreVirtualPath = "/Citrix/$($StoreName)",

        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter()]
        [System.Boolean]
        $LockedDown,

        [Parameter()]
        [System.Boolean]
        $AllowSessionReconnect,

        [Parameter()]
        [System.Boolean]
        $SubstituteDesktopImage,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    process
    {
        $targetResource = Get-TargetResource -StoreName $StoreName -AuthType $AuthType
        if ($Ensure -eq 'Present') {
            $inCompliance = $true;
            foreach ($property in $PSBoundParameters.Keys) {

                if ($targetResource.ContainsKey($property)) {

                    $expected = $PSBoundParameters[$property];
                    $actual = $targetResource[$property];
                    if ($PSBoundParameters[$property] -is [System.String[]]) {
                        if ($actual) {
                            if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual -ErrorAction silentlycontinue) {
                                Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, ($expected -join ','), ($actual -join ','));
                                $inCompliance = $false;
                            }
                        }
                        else {
                            Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, ($expected -join ','), ($actual -join ','));
                            $inCompliance = $false;
                        }
                    }
                    elseif ($expected -ne $actual) {

                        Write-Verbose ($localizedData.ResourcePropertyMismatch -f $property, $expected, $actual);
                        $inCompliance = $false;
                    }
                }

            }
        }
        else {
            $inCompliance = [System.String]::IsNullOrEmpty($targetResource.StoreName)
        }

        if ($inCompliance) {
            Write-Verbose ($localizedData.ResourceInDesiredState);
        }
        else {
            Write-Verbose ($localizedData.ResourceNotInDesiredState);
        }

        return $inCompliance;

    } #end process
} #end function Test-TargetResource


function Set-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $StoreName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Explicit","Anonymous")]
        [System.String]
        $AuthType,

        [Parameter()]
        [System.String]
        $AuthVirtualPath = "/Citrix/Authentication",

        [Parameter()]
        [System.String]
        $StoreVirtualPath = "/Citrix/$($StoreName)",

        [Parameter()]
        [System.UInt64]
        $SiteId = 1,

        [Parameter()]
        [System.Boolean]
        $LockedDown,

        [Parameter()]
        [System.Boolean]
        $AllowSessionReconnect,

        [Parameter()]
        [System.Boolean]
        $SubstituteDesktopImage,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )
    begin
    {
        AssertModule -Name Citrix.StoreFront
    }
    process
    {
        Import-Module Citrix.StoreFront -ErrorAction Stop -Verbose:$false
        $storeService = Get-STFStoreService | Where-Object { $_.FriendlyName -eq $StoreName }

        if ($Ensure -eq 'Present') {

            $setSTFStoreServiceParams = @{ }

            $targetResource = Get-TargetResource -StoreName $StoreName -AuthType $AuthType
            foreach ($property in $PSBoundParameters.Keys)
            {
                if ($targetResource.ContainsKey($property))
                {
                    $expected = $PSBoundParameters[$property];
                    $actual = $targetResource[$property];
                    if ($PSBoundParameters[$property] -is [System.String[]])
                    {
                        if ($actual)
                        {
                            if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual)
                            {
                                if (-not ($setSTFStoreServiceParams.ContainsKey($property)))
                                {
                                    Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                                    $setSTFStoreServiceParams.Add($property, $PSBoundParameters[$property])
                                }
                            }
                        }
                        else
                        {
                            Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                            $setSTFStoreServiceParams.Add($property, $PSBoundParameters[$property])
                        }
                    }
                    elseif ($expected -ne $actual)
                    {
                        if (-not ($setSTFStoreServiceParams.ContainsKey($property)))
                        {
                            Write-Verbose -Message ($localizedData.SettingResourceProperty -f $property)
                            $setSTFStoreServiceParams.Add($property, $PSBoundParameters[$property])
                        }
                    }
                }
            }

            if ($null -eq $storeService)
            {
                $addSTFStoreServiceParams = @{
                    VirtualPath = $StoreVirtualPath
                    SiteId = $SiteId
                    FriendlyName = $StoreName
                }
                if ($AuthType -eq 'Explicit')
                {
                    Write-Verbose -Message ($localizedData.RunningGetSTFAuthenticationService -f $AuthVirtualPath)
                    $addSTFStoreServiceParams['AuthenticationService'] = Get-STFAuthenticationService -VirtualPath $AuthVirtualPath
                }
                elseif ($AuthType -eq 'Anonymous')
                {
                    $addSTFStoreServiceParams['Anonymous'] = $true
                }
                Write-Verbose -Message $localizedData.RunningAddSTFStoreService
                $storeService = Add-STFStoreService @addSTFStoreServiceParams
            }

            foreach ($parameterName in $($setSTFStoreServiceParams.Keys))
            {
                if ($parameterName -notin 'LockedDown','AllowSessionReconnect','SubstituteDesktopImage')
                {
                    $setSTFStoreServiceParams.Remove($parameterName)
                }
            }
            Write-Verbose -Message $localizedData.RunningSetSTFStoreService
            $storeService | Set-STFStoreService @setSTFStoreServiceParams -Confirm:$false
        }
        else
        {
            Write-Verbose -Message $localizedData.RunningRemoveSTFStoreService
            $StoreService | Remove-STFStoreService -confirm:$false
        }

    } #end process
} #end function Set-TargetResource


## Import the XD7Common library functions
$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'VE_XD7Common');

Export-ModuleMember -Function *-TargetResource;
