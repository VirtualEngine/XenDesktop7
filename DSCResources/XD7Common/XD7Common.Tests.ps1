$here = Split-Path -Parent $MyInvocation.MyCommand.Path;
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".");
. "$here\$sut";

## Dot source XD7Common functions
$moduleParent = Split-Path -Path $here -Parent;
Get-ChildItem -Path "$moduleParent\XD7Common" -Include *.ps1 -Exclude '*.Tests.ps1' -Recurse |
    ForEach-Object { . $_.FullName; }

Describe 'cXD7Role\ResolveXDSetupMedia' {
    $testDrivePath = (Get-PSDrive -Name TestDrive).Root  
    [ref] $null = New-Item -Path 'TestDrive:\x86\Xen Desktop Setup' -ItemType Directory;
    [ref] $null = New-Item -Path 'TestDrive:\x86\Xen Desktop Setup\XenDesktopServerSetup.exe' -ItemType File;
    [ref] $null = New-Item -Path 'TestDrive:\x86\Xen Desktop Setup\XenDesktopVdaSetup.exe' -ItemType File;
    [ref] $null = New-Item -Path 'TestDrive:\x64\Xen Desktop Setup' -ItemType Directory;
    [ref] $null = New-Item -Path 'TestDrive:\x64\Xen Desktop Setup\XenDesktopServerSetup.exe' -ItemType File;
    [ref] $null = New-Item -Path 'TestDrive:\x64\Xen Desktop Setup\XenDesktopVdaSetup.exe' -ItemType File;

    $architecture = 'x86';
    if ([System.Environment]::Is64BitOperatingSystem) { $architecture = 'x64' }
    
    foreach ($role in @('Controller','Studio','Licensing','Director','Storefront')) {
        It "resolves $role role to XenDesktopServerSetup.exe." {
            $setup = ResolveXDSetupMedia -Role $role -SourcePath $testDrivePath;
            $setup.EndsWith('XenDesktopServerSetup.exe') | Should Be $true;
            $setup.Contains($architecture) | Should Be $true;
        }
    }
    
    It 'throws with no valid installer found.' {
        [ref] $null = New-Item -Path 'TestDrive:\Empty' -ItemType Directory;
        { ResolveXDSetupMedia -Role $role -SourcePath "$testDrivePath\Empty" } | Should Throw;
    }  

} #end describe cXD7Role\ResolveXDSetupMedia
