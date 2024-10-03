$Aktion = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\downloader\runner.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At 01:00
$t2 = New-ScheduledTaskTrigger -Once -At 01:00 `
        -RepetitionInterval (New-TimeSpan -Minutes 15) `
        -RepetitionDuration (New-TimeSpan -Hours 23 -Minutes 55)
$Trigger.Repetition = $t2.Repetition
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
Register-ScheduledTask -Action $Aktion -Trigger $Trigger -Principal $Principal -TaskName "werkzeugdateiupdater-dl-interval" -Description "werkzeugdateiupdater-dl" -Settings $Settings
