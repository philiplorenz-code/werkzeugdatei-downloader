if (-not (Get-Module powershell-yaml -ListAvailable)) {
  try {
    Install-Module powershell-yaml -Scope CurrentUser -Force
  }
  catch {
    return
  }
}

function logToFile($logPath, $fileName, $currentUser) {
  $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logMessage = "$currentTime - Datei: $fileName - Benutzer: $currentUser`n"
  
  if (!(Test-Path -Path $logPath)) {
    try {
      New-Item -ItemType File -Path $logPath -ErrorAction Stop
    }
    catch {
      Write-Error "Failed to create log file: $_"
      return $false
    }
  }

  try {
    Add-Content -Path $logPath -Value $logMessage -ErrorAction Stop
  }
  catch {
    Write-Error "Failed to write to log file: $_"
    return $false
  }
  
  return $true
}

function logToFileInit($logPath) {
  $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logMessage = "$currentTime - werkzeugdownloader wird gestartet..`n"
  
  if (!(Test-Path -Path $logPath)) {
    try {
      New-Item -ItemType File -Path $logPath -ErrorAction Stop
    }
    catch {
      Write-Error "Failed to create log file: $_"
      return $false
    }
  }

  try {
    Add-Content -Path $logPath -Value $logMessage -ErrorAction Stop
  }
  catch {
    Write-Error "Failed to write to log file: $_"
    return $false
  }
  
  return $true
}

function importConfig {
  try {
    return Get-Content ./download.yml | ConvertFrom-Yaml
  }
  catch {
    return
  }
}

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
  }
  catch {
  }
}



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
  }
  
  return $null
}

function LoadCurrentHashes {
  try {
    $config = importConfig
    $filesToCheck = $config.observe
    $hashLog = $config.hashLog
    $fileAndOldHash = @{}
    foreach ($fileToCheck in $filesToCheck) {
      $fileAndOldHash.Add($fileToCheck, (Get-StoredHashValue -hashLog $hashLog -fileName $fileToCheck))
    }
    return $fileAndOldHash
  }
  catch {
  }

  return $null
}

function currentuser {
  try {
    return whoami
  }
  catch {
    logToFile -logPath $config.logfile -fileName "currentuser" -currentUser (currentuser)
  }

  return $null
}

function DownloadFileAndUpdateHash($remoteFile, $hashObservedFile) {

  $config =  importConfig
  # Definiere den Basispfad
  $basePath = $config.downloaddir

  $m200Path = Join-Path -Path $basePath -ChildPath "M200"
  $x200Path = Join-Path -Path $basePath -ChildPath "X200"

  # Überprüfe, ob der erste Ordner existiert und erstelle ihn, falls er nicht existiert
  if (!(Test-Path -Path $m200Path)) {
      New-Item -ItemType Directory -Path $m200Path
  }

  # Überprüfe, ob der zweite Ordner existiert und erstelle ihn, falls er nicht existiert
  if (!(Test-Path -Path $x200Path)) {
      New-Item -ItemType Directory -Path $x200Path
  }




  try {
    $config = importConfig
    if ($remoteFile -like "*Tooling.atrx*" -or $remoteFile -like "*ST.tlgx*") {
      Copy-Item -Path $remoteFile -Destination ($config.downloaddir + "/X200/" + (Split-Path -Path $remoteFile -Leaf))
      updateSettings -remoteFile $remoteFile -machine "X200"
    }
    elseif ($remoteFile -like "*M200*") {
      Copy-Item -Path $remoteFile -Destination ($config.downloaddir + "/M200/" +  (Split-Path -Path $remoteFile -Leaf))
      updateSettings -remoteFile $remoteFile -machine "M200"
    }
    Update-StoredHashValue -hashLog $config.hashLog -fileName $remoteFile -hash $hashObservedFile
  }
  catch {
  }
}

function updateSettings($remoteFile, $machine) {
  try {
    $config = importConfig
    if (!(Test-Path -Path $config.unarchivepath)) {
      New-Item -ItemType Directory -Path $config.unarchivepath -ErrorAction Stop
    }
    
    Remove-Item -Path "$($config.unarchivepath)\*" -Recurse

    $formatApplyFileInfo = formatApplyFileInfo -settingFileToBeApplied $remoteFile -machine $machine
    if ($machine -eq "M200") {
      $settings = $config.m200settings
    }
    elseif ($machine -eq "X200") {
      $settings = $config.x200settings
    }

    # Settings-Datei umbenennen
    $basePath = Split-Path -Path $settings -Parent
    $originalFileName = Split-Path -Path $settings -Leaf
    $newFileName = $originalFileName -replace "\.settingsx$", ".zip"
    $oldPath = Join-Path -Path $basePath -ChildPath $originalFileName
    $zipSettings = Join-Path -Path $basePath -ChildPath $newFileName
    Move-Item -Path $oldPath -Destination $zipSettings -Force

    Expand-Archive $zipSettings -DestinationPath $config.unarchivepath -Force
    Copy-Item -Path $formatApplyFileInfo.Path -Destination ($config.unarchivepath + "/" + $formatApplyFileInfo.Extension) -Force

    $previousLocation = Get-Location
    Set-Location $config.unarchivepath
    Get-ChildItem | Compress-Archive -DestinationPath $zipSettings -Force
    Set-Location $previousLocation
    Move-Item -Path $zipSettings -Destination $oldPath -Force

    Remove-Item -Path "$($config.unarchivepath)\*" -Recurse
    
  }
  catch {
  }
}


function formatApplyFileInfo($settingFileToBeApplied, $machine) {
  try {
    $machinePath = "/" + $machine
    $config = importConfig
    $dlDir = $config.downloaddir + $machinePath
  
    $fileName = Split-Path -Path $settingFileToBeApplied -Leaf
    $newPath = Join-Path -Path $dlDir -ChildPath $fileName
    $fileExtension = $fileName.Split('.')[-1]
  
    $fileObject = New-Object PSObject -Property @{
      Path      = $newPath
      Extension = $fileExtension
    }
  
    return $fileObject
  }
  catch {
  }

  return $null
}


$ObservedFiles = LoadCurrentHashes
if ($null -eq $ObservedFiles) {
  return
}
$ObservedFilePaths = $ObservedFiles.Keys
$config = importConfig
logToFileInit -logPath $config.logfile
foreach ($ObservedFile in $ObservedFilePaths) {
  try {
    $hashObservedFile = (Get-FileHash -Path $ObservedFile).Hash
    $hashOldFile = $ObservedFiles.($ObservedFile)
    if ($hashObservedFile -eq $hashOldFile) {
      Write-Host "File $($ObservedFile.($ObservedFile)) has not changed"
    }
    else {
      Write-Host "File $($ObservedFile.($ObservedFile)) has changed"
      DownloadFileAndUpdateHash -remoteFile $ObservedFile -hashObservedFile $hashObservedFile
      logToFile -logPath $config.logfile -fileName $ObservedFile -currentUser (currentuser)
    }
  }
  catch {
  }
}