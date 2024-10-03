# Wichtig
Folgende Werte müssen angepasst werden:

## download.yml
Hier müssen die Pfade korrekt gesetzt werden. Bei Windows gibt es die Problematik mit Backslash. Damit alles funktioniert müssen immer doppelte Backslashes gesetzt werden. Beispiel:

Aus "C:\downloader\download.yaml" wird
"C:\\downloader\\download.yaml"


Ist doof, ist aber leider so. Details zu der Problematik können hier nachgelesen werden: https://www.geeksforgeeks.org/how-to-escape-the-special-character-in-yaml-with-examples/

## hashlog.csv
Datei am besten leeren. Dazu die Datei mit dem Editor oder Notepad++ oder Visual Studio Code öffnen und alles außer den Überschriften (erste Zeile) weglöschen.

## runner.ps1
Hier müssen die Werte der ersten Zeilen angepasst werden.
$scriptPath muss dem Pfad der Datei "werkzeugdateidl.ps1" entsprechen
$logFilePath entspricht dem Pfad der Datei, in welche die Log-Nachrichten geschrieben werden sollen. Dieser ist frei wählbar, sollte aber auch im Ordner der "werkzeugdateidl.ps1" sein.

## deploy_interval.ps1 und deploy_startup.ps1
Bei beiden Dateien muss in Zeile 1 der Pfad zu der "runner.ps1" angegeben werden. Wichtig: nicht versehentlich das "-File" weglöschen.

## Test der Automatismus
Um zu prüfen, ob alles funktioniert, kann die runner.ps1 ausgeführt werden. Hierzu Visual Studio Code öffnen. In VSCode dann den ganzen Ordner öffnen, in welchem sich das Projekt befindet. Also den Ordner wo die runner.ps1 liegt.
Anschließend die runner.ps1 ausführen.
Wenn das alles funktioniert, dann können die Scheduled Tasks angelegt werden. Dazu identisch zur runner.ps1 die Dateien deploy_interval.ps1 und deploy_startup.ps1 ausführen.

---
# Werkzeugdatei Updater

Dieses Skript überwacht bestimmte Dateien und führt Aktionen aus, wenn diese Dateien geändert wurden. Bei Änderungen wird die Datei in ein bestimmtes Verzeichnis kopiert und der Hash-Wert der Datei wird aktualisiert. Außerdem wird eine Protokolldatei mit Informationen zu den durchgeführten Aktionen erstellt.

## Verwendung des Skripts

### Konfiguration

Bevor Sie das Skript verwenden können, müssen Sie einige Einstellungen in der Datei `download.yml` vornehmen. Die Datei `download.yml` enthält die folgenden Einstellungen:

- `logfile`: Der Pfad zur Protokolldatei, in der Informationen zu den durchgeführten Aktionen gespeichert werden.
- `observe`: Eine Liste von Dateipfaden, die das Skript überwachen soll.
- `downloaddir`: Das Verzeichnis, in das geänderte Dateien kopiert werden.
- `hashlog`: Der Pfad zur CSV-Datei, die die Hash-Werte der überwachten Dateien speichert.
- `x200settings` und `m200settings`: Die Pfade zu den Einstellungsdateien für die X200- und M200-Maschinen.
- `unarchivepath`: Der Pfad zum Verzeichnis, in dem temporäre Dateien während des Aktualisierungsprozesses gespeichert werden.

### Starten des Skripts

Nachdem Sie die `download.yml` konfiguriert haben, können Sie das Skript `werkzeugdateidl.ps1` ausführen. Es erfordert keine zusätzlichen Argumente oder Parameter.

## Was passiert im Hintergrund?

Das Skript lädt zuerst die Konfiguration aus der `download.yml`-Datei und liest die aktuelle Hash-Werte aus der `hashlog.csv`-Datei. Anschließend überprüft es, ob die Hash-Werte der überwachten Dateien geändert wurden. Bei Änderungen wird die Datei in das in `downloaddir` angegebene Verzeichnis kopiert und der Hash-Wert in der `hashlog.csv`-Datei aktualisiert.

Falls die Datei, die sich geändert hat, eine Einstellungsdatei für die X200- oder M200-Maschinen ist, führt das Skript zusätzliche Schritte aus. Es benennt die alte Einstellungsdatei um, entpackt sie, fügt die neue Datei hinzu, verpackt sie wieder und benennt sie zurück.

Das Skript protokolliert alle durchgeführten Aktionen in der `updater.log`-Datei. Falls während des Prozesses ein Fehler auftritt, wird der Fehler ebenfalls in der `updater.log`-Datei protokolliert.
