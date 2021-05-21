# Windows 10 Startmenü neu starten
# *********************************
# Diese Skript beendet den "ShellExperienceHost"
# Anwendung: Nach der Benutzeranmeldung
# Infos werden gespeichert in: c:\tmp\paedml-w10-fix-startmenu.txt
# *********************************
# Version 1.5 - 23.06.2020
# Version 1.4 - 05.05.2020
# Version 1.3 - 13.10.2019
# Version 1.2 - 05.12.2018

param(
    [Switch]
    $Log
)

# Variablen
# Log
$logFile = 'c:\tmp\paedml-w10-fix-startmenu.txt'

# Timeout in Sekunden
$timeoutMAX = 180

# Prozess zum Stoppen
# Windows 10 
$NTVersion = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ReleaseId

switch ($NTVersion)
{
    '1803' {
        $targetPROCESS = "ShellExperienceHost"
    }
    '1909' {
        $targetPROCESS = "StartMenuExperienceHost"
    }
    default {
        $targetPROCESS = "StartMenuExperienceHost"
    }
}

# Skript gestartet am ...
$dateSTART = Get-Date

# Etwas Logging zum Start
if ($Log)
{
  '' | Add-Content -Path $logFile -Force -Encoding UTF8
  ('Skript gestartet am {0}' -f $dateSTART) | Add-Content -Path $logFile -Force -Encoding UTF8
  ('Config_Timeout       : {0}' -f $timeoutMAX) | Add-Content -Path $logFile -Force -Encoding UTF8
  ('Config_TargetProcess : {0}' -f $targetPROCESS) | Add-Content -Path $logFile -Force -Encoding UTF8
}

# Start
# Process to watch for
try
{
    $ErrorActionPreference = 'STOP'
    $counter = 0
    do
    {
        $processToWatch = Get-Process -Name $targetPROCESS -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        $counter++
    }
    until ($null -ne $processToWatch -or $counter -eq $timeoutMAX)

    # Wait more
    $i = 0
    do
    {
        Start-Sleep -Seconds 1
        $i++
    }
    while ($i -le $counter)

    if ($null -ne $processToWatch)
    {
        $dateProcessFound = Get-Date
        if ($Log)
        {
          $message = ('{0} gefunden nach : {1} Sekunden.' -f $targetPROCESS, ([Math]::Round(($dateProcessFound - $dateSTART).TotalSeconds, 2)))
          $message | Add-Content -Path $logFile -Force -Encoding UTF8
        }
    }
    else
    {
        if ($Log)
        {
          $message = ('Der Windows-Prozess {0} wurde trotz der Wartezeit von {1} Sekunden nicht gefunden.' -f $targetPROCESS, $counter)
          $message | Add-Content -Path $logFile -Force -Encoding UTF8
          ('Skript beendet am {0}' -f (Get-Date)) | Add-Content -Path $logFile -Force -Encoding UTF8
        }
        [System.Environment]::Exit(13)
    }

    # Restart target process
    Stop-Process -Name $targetPROCESS
    if ($Log)
    {
      ('Neustart von {0} um: {1}' -f $targetPROCESS, (Get-Date)) | Add-Content -Path $logFile -Force -Encoding UTF8
      ('Skript beendet am {0}' -f (Get-Date)) | Add-Content -Path $logFile -Force -Encoding UTF8
    }
}
catch
{
    ('Fehler: {0}' -f $_.Exception) | Add-Content -Path $logFile -Force -Encoding UTF8
}