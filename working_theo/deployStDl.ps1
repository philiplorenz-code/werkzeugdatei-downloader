$Aktion = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Werkzeugdownloader\downloader\runner.ps1"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
Register-ScheduledTask -Action $Aktion -Trigger $Trigger -Principal $Principal -TaskName "werkzeugdateiupdater-dl" -Description "werkzeugdateiupdater-dl" -Settings $Settings
