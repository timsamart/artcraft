param([string]$ProgramsPath = [Environment]::GetFolderPath('Programs'))
$ErrorActionPreference = 'Stop'
$config = Get-Content (Join-Path $PSScriptRoot 'app.json') -Raw | ConvertFrom-Json
$icon = Join-Path $PSScriptRoot $config.ico
if (-not (Test-Path -LiteralPath $icon)) { throw "Missing icon: $icon" }
$shell = New-Object -ComObject WScript.Shell
$shortcuts = @(Get-ChildItem -LiteralPath $ProgramsPath -Filter "$($config.title).lnk" -File -Recurse)
if ($shortcuts.Count -eq 0) { throw "No $($config.title) shortcut found. Install the app first." }
foreach ($file in $shortcuts) {
    $shortcut = $shell.CreateShortcut($file.FullName)
    $target = $shortcut.TargetPath
    $shortcut.IconLocation = "$icon,0"
    $shortcut.Save()
    $check = $shell.CreateShortcut($file.FullName)
    if ($check.IconLocation -ne "$icon,0" -or $check.TargetPath -ne $target) { throw "Shortcut verification failed: $($file.FullName)" }
    Write-Output "Updated: $($file.FullName)"
}
if (-not ('CraftSingleIconRefresh' -as [type])) {
    Add-Type 'using System; using System.Runtime.InteropServices; public static class CraftSingleIconRefresh { [DllImport("shell32.dll")] public static extern void SHChangeNotify(uint e,uint f,IntPtr a,IntPtr b); }'
}
[CraftSingleIconRefresh]::SHChangeNotify(0x08000000,0,[IntPtr]::Zero,[IntPtr]::Zero)
