Set-Location "C:\Werkzeugdownloader\downloader"
# Pfad zu dem auszuführenden Skript
$ScriptPath = "C:\Werkzeugdownloader\downloader\werkzeugdateidl.ps1"

# Erstellen Sie den Pfad zur Logdatei auf dem Desktop des aktuellen Benutzers
$LogFilePath = "C:\Users\theo_\Desktop\scriptlog.txt"

# Fügen Sie das aktuelle Datum und die Uhrzeit zur Logdatei hinzu
Add-Content $LogFilePath -Value ("Skript gestartet am: " + (Get-Date).ToString())

try {
    # Führen Sie das Skript aus
    & $ScriptPath

    # Wenn das Skript erfolgreich ausgeführt wurde, fügen Sie eine Erfolgsmeldung zur Logdatei hinzu
    Add-Content $LogFilePath -Value ("Skript erfolgreich beendet am: " + (Get-Date).ToString())
} 
catch {
    # Wenn ein Fehler aufgetreten ist, fügen Sie die Fehlerinformationen zur Logdatei hinzu
    Add-Content $LogFilePath -Value ("Fehler beim Ausführen des Skripts am: " + (Get-Date).ToString())
    Add-Content $LogFilePath -Value ("Fehlerdetails: " + $_.Exception.Message)
}
Add-Content $LogFilePath -Value ("Errordump: " + $Error)
