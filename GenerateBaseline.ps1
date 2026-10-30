# GenerateBaseline.ps1 - Création de l'état de référence SHA-256
$config = Get-Content "C:\HIDS\hids.config.json" -Raw | ConvertFrom-Json

function Get-FileHashSHA256($filePath) {
    if (Test-Path $filePath -PathType Leaf) {
        $hash = Get-FileHash -Algorithm SHA256 -Path $filePath
        return @{
            Path = $filePath
            Hash = $hash.Hash
            LastModified = (Get-Item $filePath).LastWriteTime
        }
    }
}

$baseline = @()
foreach ($target in $config.Targets) {
    $info = Get-FileHashSHA256 $target
    if ($info) {
        $baseline += $info
        Write-Host "Fichier ajouté : $($info.Path)"
    }
}

$baseline | ConvertTo-Json | Out-File $config.BaselinePath -Encoding UTF8
Write-Host "Baseline créée avec succès à $($config.BaselinePath)"
