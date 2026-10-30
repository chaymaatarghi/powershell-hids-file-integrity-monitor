# Monitor.ps1 - HIDS PowerShell : surveillance, logs et alertes SMTP
function Get-CurrentFiles {
    param([string]$target)
    if (!(Test-Path $target)) { return @() }
    $it = Get-Item $target
    if ($it.PSIsContainer) {
        return Get-ChildItem $target -File -Recurse -ErrorAction SilentlyContinue |
               Select-Object -ExpandProperty FullName
    } else {
        return @($it.FullName)
    }
}

function Compare-Files {
    param([object]$config, [hashtable]$mapTemplate)
    $map = @{}
    foreach ($k in $mapTemplate.Keys) { $map[$k] = $mapTemplate[$k] }
    $changes = @()
    foreach ($t in $config.Targets) {
        $files = Get-CurrentFiles -target $t
        foreach ($p in $files) {
            try {
                $h = (Get-FileHash -Algorithm SHA256 -Path $p -ErrorAction Stop).Hash
            } catch {
                $h = ""
            }
            if ($map.ContainsKey($p)) {
                if ($map[$p].Hash -ne $h) {
                    $changes += [pscustomobject]@{Type='Modified'; Path=$p}
                }
                $map.Remove($p) | Out-Null
            } else {
                $changes += [pscustomobject]@{Type='Created'; Path=$p}
            }
        }
    }
    foreach ($left in $map.Keys) {
        $changes += [pscustomobject]@{Type='Deleted'; Path=$left}
    }
    return ,$changes
}

function Send-HidsMail {
    param($config,[string]$subject,[string]$body)
    try {
        $cred = Import-Clixml -Path $config.CredPath
    } catch {
        throw "Impossible de charger les identifiants SMTP ($($config.CredPath)) : $($_.Exception.Message)"
    }
    Send-MailMessage -SmtpServer $config.Smtp.Server -Port $config.Smtp.Port -UseSsl `
        -Credential $cred -From $config.Smtp.From -To $config.Smtp.To `
        -Subject ("{0} {1}" -f $config.Smtp.SubjectPrefix,$subject) `
        -Body $body -BodyAsHtml:$false
}

function Write-Log {
    param([string]$msg, [string]$path)
    $line = ("[{0}] {1}" -f (Get-Date -Format u), $msg)
    $dir = Split-Path $path -Parent
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $line | Out-File -FilePath $path -Append -Encoding UTF8
}

while ($true) {
    try {
        $config = Get-Content "C:\HIDS\hids.config.json" -Raw | ConvertFrom-Json
    } catch {
        Write-Host "ERREUR: impossible de charger hids.config.json : $($_.Exception.Message)"
        Start-Sleep -Seconds 30
        continue
    }

    $logPath = if ($config.LogPath) { $config.LogPath } else { "C:\HIDS\monitor_log.txt" }
    if (Test-Path $config.BaselinePath) {
        $baseline = Get-Content $config.BaselinePath -Raw | ConvertFrom-Json
    } else {
        Write-Log "Baseline non trouvee: $($config.BaselinePath)" $logPath
        $baseline = @()
    }
    $map = @{}
    foreach ($b in $baseline) { $map[$b.Path] = $b }
    $changes = Compare-Files -config $config -mapTemplate $map
    if ($changes.Count -gt 0) {
        $body = ($changes | Out-String)
        Write-Host "Changements détectés :`n$body"
        Write-Log "Changements détectés:`n$body" $logPath
        try {
            Send-HidsMail -config $config -subject "Changements détectés" -body $body
            Write-Log "Email envoye: sujet='Changements détectés'" $logPath
        } catch {
            Write-Log "Erreur envoi email: $($_.Exception.Message)" $logPath
        }
    } else {
        Write-Host "Aucun changement."
        Write-Log "Aucun changement." $logPath
    }
    $sec = 300
    try { $sec = [int]($config.ScanIntervalMinutes * 60) } catch {}
    Start-Sleep -Seconds $sec
}
