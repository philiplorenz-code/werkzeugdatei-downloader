# Installiere das Modul, wenn es nicht bereits vorhanden ist
if (-not (Get-Module powershell-yaml -ListAvailable)) {
  try {
    Install-Module powershell-yaml -Scope CurrentUser -Force
  }
  catch {
    Write-Host -ForegroundColor Red "Fehler: Das Modul 'powershell-yaml' konnte nicht installiert werden."
    return
  }
}

# Funktion zur Ausgabe in ein Logfile
function logToFile($logPath, $fileName, $currentUser) {
  $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logMessage = "$currentTime - Datei: $fileName - Benutzer: $currentUser`n"
  
  if (!(Test-Path -Path $logPath)) {
    try {
      New-Item -ItemType File -Path $logPath -ErrorAction Stop
      Write-Host -ForegroundColor Green "Log-Datei wurde erfolgreich erstellt: $logPath"
    }
    catch {
      Write-Host -ForegroundColor Red "Fehler: Log-Datei konnte nicht erstellt werden. $_"
      return $false
    }
  }

  try {
    Add-Content -Path $logPath -Value $logMessage -ErrorAction Stop
    Write-Host -ForegroundColor Green "Log-Eintrag erfolgreich hinzugefügt: $logMessage"
  }
  catch {
    Write-Host -ForegroundColor Red "Fehler: Log-Eintrag konnte nicht geschrieben werden. $_"
    return $false
  }
  
  return $true
}

# Initialisiere das Logfile mit einer Startmeldung
function logToFileInit($logPath) {
  $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logMessage = "$currentTime - werkzeugdownloader wird gestartet..`n"
  
  if (!(Test-Path -Path $logPath)) {
    try {
      New-Item -ItemType File -Path $logPath -ErrorAction Stop
      Write-Host -ForegroundColor Green "Log-Datei wurde erfolgreich erstellt: $logPath"
    }
    catch {
      Write-Host -ForegroundColor Red "Fehler: Log-Datei konnte nicht erstellt werden. $_"
      return $false
    }
  }

  try {
    Add-Content -Path $logPath -Value $logMessage -ErrorAction Stop
    Write-Host -ForegroundColor Green "Startmeldung erfolgreich ins Logfile geschrieben."
  }
  catch {
    Write-Host -ForegroundColor Red "Fehler: Startmeldung konnte nicht ins Logfile geschrieben werden. $_"
    return $false
  }
  
  return $true
}

# YAML-Konfiguration importieren
function importConfig {
  try {
    Write-Host -ForegroundColor Yellow "Lade Konfigurationsdatei..."
    return Get-Content ./download.yml | ConvertFrom-Yaml
  }
  catch {
    Write-Host -ForegroundColor Red "Fehler: Konfigurationsdatei konnte nicht geladen werden."
    return
  }
}

# Hash-Wert aktualisieren
function Update-StoredHashValue ($hashLog, $fileName, [string]$hash) {
  try {
    $logFileContent = New-Object System.Collections.ArrayList
    if (Test-Path -Path $hashLog) {
      $csvContent = Import-Csv -Path $hashLog 
      foreach ($item in $csvContent) {
        if ($item.FileName -ne $fileName) {
          $null = $logFileContent.Add($item)
        }
      }
    }
    $null = $logFileContent.Add((New-Object PSObject -Property @{FileName = $fileName; Hash = $hash }))
    $logFileContent | Export-Csv -Path $hashLog -NoTypeInformation
    Write-Host -ForegroundColor Green "Hash-Wert für $fileName erfolgreich aktualisiert."
  }
  catch {
    Write-Host -ForegroundColor Red "Fehler: Hash-Wert für $fileName konnte nicht aktualisiert werden."
  }
}

# Hash-Wert abrufen
function Get-StoredHashValue ($hashLog, $fileName) {
  try {
    if (Test-Path -Path $hashLog) {
      $logFileContent = Import-Csv -Path $hashLog
      $fileRecord = $logFileContent | Where-Object { $_.FileName -eq $fileName }
      if ($null -ne $fileRecord) {
        return $fileRecord.Hash
      }
    }
  }
  catch {
    logToFile -logPath $config.logfile -fileName $fileName -currentUser (currentuser)
    Write-Host -ForegroundColor Red "Fehler: Konnte gespeicherten Hash-Wert nicht abrufen."
  }
  
  return $null
}

# Aktuelle Hash-Werte laden
function LoadCurrentHashes {
  try {
    $config = importConfig
    $filesToCheck = $config.observe
    $hashLog = $config.hashLog
    $fileAndOldHash = @{}
    foreach ($fileToCheck in $filesToCheck) {
      $fileAndOldHash.Add($fileToCheck, (Get-StoredHashValue -hashLog $hashLog -fileName $fileToCheck))
    }
    Write-Host -ForegroundColor Yellow "Alle Hash-Werte erfolgreich geladen."
    return $fileAndOldHash
  }
  catch {
    Write-Host -ForegroundColor Red "Fehler: Konnte aktuelle Hash-Werte nicht laden."
  }

  return $null
}

# Benutzer ermitteln
function currentuser {
  try {
    return whoami
  }
  catch {
    logToFile -logPath $config.logfile -fileName "currentuser" -currentUser (currentuser)
    Write-Host -ForegroundColor Red "Fehler: Konnte Benutzername nicht ermitteln."
  }

  return $null
}

# Datei herunterladen und Hash aktualisieren
function DownloadFileAndUpdateHash($remoteFile, $hashObservedFile) {
  $config =  importConfig
  $basePath = $config.downloaddir

  $m200Path = Join-Path -Path $basePath -ChildPath "M200"
  $x200Path = Join-Path -Path $basePath -ChildPath "X200"

  if (!(Test-Path -Path $m200Path)) {
    New-Item -ItemType Directory -Path $m200Path
    Write-Host -ForegroundColor Green "Ordner $m200Path erfolgreich erstellt."
  }

  if (!(Test-Path -Path $x200Path)) {
    New-Item -ItemType Directory -Path $x200Path
    Write-Host -ForegroundColor Green "Ordner $x200Path erfolgreich erstellt."
  }

  try {
    if ($remoteFile -like "*Tooling.atrx*" -or $remoteFile -like "*ST.tlgx*") {
      Copy-Item -Path $remoteFile -Destination ($config.downloaddir + "/X200/" + (Split-Path -Path $remoteFile -Leaf))
      #updateSettings -remoteFile $remoteFile -machine "X200"
      Write-Host -ForegroundColor Green "Datei $remoteFile erfolgreich in X200-Verzeichnis kopiert."
    }
    elseif ($remoteFile -like "*M200*") {
      Copy-Item -Path $remoteFile -Destination ($config.downloaddir + "/M200/" +  (Split-Path -Path $remoteFile -Leaf))
      #updateSettings -remoteFile $remoteFile -machine "M200"
      Write-Host -ForegroundColor Green "Datei $remoteFile erfolgreich in M200-Verzeichnis kopiert."
    }
    Update-StoredHashValue -hashLog $config.hashLog -fileName $remoteFile -hash $hashObservedFile
  }
  catch {
    Write-Host -ForegroundColor Red "Fehler: Datei konnte nicht heruntergeladen werden."
  }
}

# Hauptprozess starten
$ObservedFiles = LoadCurrentHashes
if ($null -eq $ObservedFiles) {
  Write-Host -ForegroundColor Red "Fehler: Keine Dateien zur Beobachtung gefunden."
  return
}

$config = importConfig
logToFileInit -logPath $config.logfile

foreach ($ObservedFile in $ObservedFiles.Keys) {
  try {
    $hashObservedFile = (Get-FileHash -Path $ObservedFile).Hash
    $hashOldFile = $ObservedFiles.($ObservedFile)
    if ($hashObservedFile -eq $hashOldFile) {
      Write-Host -ForegroundColor Yellow "Datei $ObservedFile wurde nicht geändert."
    }
    else {
      Write-Host -ForegroundColor Cyan "Datei $ObservedFile wurde geändert. Herunterladen..."
      DownloadFileAndUpdateHash -remoteFile $ObservedFile -hashObservedFile $hashObservedFile
      logToFile -logPath $config.logfile -fileName $ObservedFile -currentUser (currentuser)
    }
  }
  catch {
    Write-Host -ForegroundColor Red "Fehler bei der Verarbeitung von $ObservedFile."
  }
}