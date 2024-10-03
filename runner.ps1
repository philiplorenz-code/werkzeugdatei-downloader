# Pfade definieren
$scriptPath = "C:\downloader\werkzeugdateidl.ps1"
$logFilePath = "C:\downloader\scheduler_log.log"

# Funktion zum Schreiben ins Log und Beschränkung auf die letzten 100 Zeilen
function Write-Log {
    param (
        [string]$message,
        [string]$logPath
    )

    # Zeitstempel hinzufügen
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"

    # Log-Nachricht hinzufügen
    Add-Content -Path $logPath -Value $logMessage

    # Überprüfen, ob mehr als 100 Zeilen in der Log-Datei sind
    $logContent = Get-Content -Path $logPath
    if ($logContent.Count -gt 100) {
        $logContent = $logContent | Select-Object -Last 100
        Set-Content -Path $logPath -Value $logContent
    }
}

try {
    # In das Verzeichnis des Skripts wechseln
    $scriptDirectory = Split-Path -Path $scriptPath
    Set-Location -Path $scriptDirectory

    # Skript ausführen
    & $scriptPath

    # Erfolgslog schreiben
    Write-Log -message "werkzeugdateidl.ps1 wurde erfolgreich aufgerufen." -logPath $logFilePath
}
catch {
    # Fehlermeldung loggen, falls etwas schiefgeht
    Write-Log -message "Fehler beim Aufruf von werkzeugdateidl.ps1: $_" -logPath $logFilePath
}