# DetectChanges.ps1 - Comparaison des fichiers à la baseline SHA-256
$config = Get-Content "C:\HIDS\hids.config.json" -Raw | ConvertFrom-Json
$baseline = Get-Content $config.BaselinePath -Raw | ConvertFrom-Json

$map = @{}
foreach ($b in $baseline) { $map[$b.Path] = $b }
$changes = @()

foreach ($t in $config.Targets) {
    if (Test-Path $t) {
        $item = Get-Item $t
        if ($item.PSIsContainer) {
            $files = Get-ChildItem $t -File -Recurse | Select-Object -ExpandProperty FullName
        } else {
            $files = @($item.FullName)
        }
        foreach ($p in $files) {
            $h = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
            if ($map.ContainsKey($p)) {
                if ($map[$p].Hash -ne $h) {
                    $changes += [pscustomobject]@{ Type='Modified'; Path=$p }
                }
                $map.Remove($p) | Out-Null
            } else {
                $changes += [pscustomobject]@{ Type='Created'; Path=$p }
            }
        }
    }
}

foreach ($left in $map.Keys) {
    $changes += [pscustomobject]@{ Type='Deleted'; Path=$left }
}

if ($changes.Count -eq 0) {
    Write-Host "Aucun changement détecté."
} else {
    $changes | Format-Table -AutoSize
}
