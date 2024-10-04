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
