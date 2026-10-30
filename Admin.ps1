# Admin.ps1 - Menu d'administration du HIDS
try { cmd /c chcp 65001 > $null } catch {}
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

function Show-Menu {
    Clear-Host
    Write-Host "==== HIDS Admin Menu ===="
    Write-Host "1. Lister les cibles"
    Write-Host "2. Ajouter une cible"
    Write-Host "3. Supprimer une cible"
    Write-Host "4. Paramètres SMTP / identifiants"
    Write-Host "5. Envoyer un email de test"
    Write-Host "6. Régénérer la baseline"
    Write-Host "7. Voir les logs"
    Write-Host "0. Quitter"
}

do {
    Show-Menu
    $choice = Read-Host "Choix"
    switch ($choice) {
        '1' {
            $cfg = Get-Content "C:\HIDS\hids.config.json" -Raw | ConvertFrom-Json
            Write-Host "Cibles surveillées :"
            $cfg.Targets | ForEach-Object { Write-Host " - $_" }
        }
        '2' {
            $newPath = Read-Host "Entrez le chemin complet à ajouter"
            $cfg = Get-Content "C:\HIDS\hids.config.json" -Raw | ConvertFrom-Json
            $cfg.Targets += $newPath
            $cfg | ConvertTo-Json -Depth 4 | Set-Content "C:\HIDS\hids.config.json" -Encoding UTF8
            Write-Host "Cible ajoutée avec succès."
        }
        '3' {
            $cfg = Get-Content "C:\HIDS\hids.config.json" -Raw | ConvertFrom-Json
            $cfg.Targets | ForEach-Object { Write-Host $_ }
            $remove = Read-Host "Entrez le chemin à supprimer"
            $cfg.Targets = $cfg.Targets | Where-Object { $_ -ne $remove }
            $cfg | ConvertTo-Json -Depth 4 | Set-Content "C:\HIDS\hids.config.json" -Encoding UTF8
            Write-Host "Cible supprimée."
        }
        '5' {
            $cfg = Get-Content "C:\HIDS\hids.config.json" -Raw | ConvertFrom-Json
            $cred = Import-Clixml -Path $cfg.CredPath
            Send-MailMessage -SmtpServer $cfg.Smtp.Server -Port $cfg.Smtp.Port -UseSsl `
                -Credential $cred -From $cfg.Smtp.From -To $cfg.Smtp.To `
                -Subject "Test HIDS" -Body "Test réussi"
            Write-Host "Email de test envoyé avec succès."
        }
        '6' { & "C:\HIDS\GenerateBaseline.ps1" }
        '7' { Get-Content "C:\HIDS\monitor_log.txt" | Out-Host }
    }
    pause
} while ($choice -ne '0')
