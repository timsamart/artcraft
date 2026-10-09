param([string]$InstalledRoot = (Join-Path $PSScriptRoot '../../installed'))
$ErrorActionPreference = 'Stop'
$apps = @('photocraft','lightcraft','filmcraft','pdfcraft','vectorcraft','effectcraft','designcraft','wordcraft','cadcraft','gridcraft','soundcraft','deckcraft','artcraft','artcraftx')
$titles = @('PhotoCraft','LightCraft','FilmCraft','PdfCraft','VectorCraft','EffectCraft','DesignCraft','WordCraft','CADCraft','GridCraft','SoundCraft','DeckCraft','ArtCraft','ArtCraftX')
$InstalledRoot = [IO.Path]::GetFullPath($InstalledRoot)
$iconRoot = Join-Path $InstalledRoot 'icons'
New-Item -ItemType Directory -Path $iconRoot -Force | Out-Null
$shell = New-Object -ComObject WScript.Shell
$programs = [Environment]::GetFolderPath('Programs')
$backup = @()
$updated = @()
for ($i=0; $i -lt $apps.Count; $i++) {
    $app = $apps[$i]
    $ico = Join-Path $iconRoot "$app-v2.ico"
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "$app.ico") -Destination $ico -Force
    $matches = @(Get-ChildItem -LiteralPath $programs -Filter "$($titles[$i]).lnk" -File -Recurse)
    $portable = Join-Path $InstalledRoot "$app.lnk"
    if (Test-Path -LiteralPath $portable) { $matches += Get-Item -LiteralPath $portable }
    if ($matches.Count -eq 0) { throw "No launcher found for $app" }
    foreach ($file in $matches) {
        $shortcut = $shell.CreateShortcut($file.FullName)
        $backup += [PSCustomObject]@{path=$file.FullName;icon=$shortcut.IconLocation;target=$shortcut.TargetPath}
        $target = $shortcut.TargetPath
        $shortcut.IconLocation = "$ico,0"
        $shortcut.Save()
        $check = $shell.CreateShortcut($file.FullName)
        if ($check.IconLocation -ne "$ico,0" -or $check.TargetPath -ne $target) { throw "Shortcut verification failed: $($file.FullName)" }
        $updated += [PSCustomObject]@{app=$app;shortcut=$file.FullName;icon=$check.IconLocation;target=$check.TargetPath}
    }
    Write-Output "Applied and verified: $($titles[$i])"
}
$backupFile = Join-Path $iconRoot 'shortcut-backup-before-v2.json'
if (-not (Test-Path -LiteralPath $backupFile)) { $backup | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $backupFile }
$updated | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $iconRoot 'shortcut-verification-v2.json')
if (-not ('CraftIconRefresh' -as [type])) {
    Add-Type 'using System; using System.Runtime.InteropServices; public static class CraftIconRefresh { [DllImport("shell32.dll")] public static extern void SHChangeNotify(uint e,uint f,IntPtr a,IntPtr b); }'
}
[CraftIconRefresh]::SHChangeNotify(0x08000000,0, [IntPtr]::Zero,[IntPtr]::Zero)
