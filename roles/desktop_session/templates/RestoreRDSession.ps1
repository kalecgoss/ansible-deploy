$rdpPath = "C:\Windows\System32\mstsc.exe"
$resetPath = "C:\Windows\System32\reset.exe"
$qwinstaPath = "C:\Windows\System32\qwinsta.exe"
$tsconPath = "C:\Windows\System32\tscon.exe"
$logPath = "C:\Windows\Temp\RestoreRDSession_log.txt"
$rdpOptions = "C:\RestoreRDSession.rdp"
$remoteControlConf = "C:\RestoreRDSession.txt"
$sessionUser = "{{ ansible_user }}"
$delimLong = "================================================================================"
$delimShort = "****************************************"

& {
  Write-Output $delimLong
  Write-Output "RestoreRDSession started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"

  # If found NO opened SESSIONS at all ==> create new RDP session, then kill this session, after that open new session
  If ($(((& $qwinstaPath $sessionUser 2>&1) -match "No session exists" | Measure-Object -Line).Lines) -gt 0) {
    Write-Output "`nNO SESSIONS FOUND! STARTING LOCAL MSTSC ($rdpPath $rdpOptions)..."
    Start-Process -FilePath $rdpPath -ArgumentList $rdpOptions
    Start-Sleep -Seconds 5
    Write-Output "`nCURRENT SESSIONS LIST:"
    Write-Output $delimShort; & $qwinstaPath; Write-Output $delimShort
    Start-Sleep -Seconds 10
    Write-Output "`nRESET CURRENT SESSION..."
    $sessionID = (((((& $qwinstaPath 2>&1) | Select-String -Pattern "^.*$sessionUser[ ]+[0-9][0-9]*.*$") -split ("$sessionUser"))[1]) -split ("\s+"))[1]
    Write-Output "ID=$sessionID"
    & $resetPath session $sessionID
    Write-Output "`nSTOPPING ALL LOCALLY CONNECTED MSTSC PROCESSES..."
    Get-WmiObject Win32_Process | ? { $_.Path -eq $rdpPath -and $_.CommandLine -like "*$rdpOptions*" } | % { Stop-Process -Id $_.ProcessId -Force }
    Start-Sleep -Seconds 20
    Write-Output "`nCURRENT SESSIONS LIST:"
    Write-Output $delimShort; & $qwinstaPath; Write-Output $delimShort
    Write-Output "`nSTARTING LOCAL MSTSC ($rdpPath $rdpOptions) ONE MORE TIME..."
    Start-Process -FilePath $rdpPath -ArgumentList $rdpOptions
    Start-Sleep -Seconds 5
    Write-Output "`nCURRENT SESSIONS LIST:"
    Write-Output $delimShort; & $qwinstaPath; Write-Output $delimShort
    Start-Sleep -Seconds 5
  }

  # TeamViewer/AnyDesk specific code below
  $remoteControl = ""
  $remoteControl = $(Get-Content -Path $remoteControlConf).ToLower()
  Write-Output "REMOTE CONTROL TYPE DEFINED FOR THIS FARM: $remoteControl"

  If ($remoteControl -eq "anydesk") {
    Write-Output "SWITCHING TO AnyDesk MODE..."

    # Find mstsc processes
    Write-Output "`nMSTSC PROCESSES BEFORE STOP:"
    Write-Output $delimShort; Get-WmiObject Win32_Process | ? { $_.Path -eq $rdpPath } | Select-Object CommandLine, ProcessID, SessionID, CreationDate; Write-Output $delimShort

    # Kill all previously local-started mstsc processes
    Write-Output "`nSTOPPING ALL LOCALLY CONNECTED MSTSC PROCESSES..."
    Get-WmiObject Win32_Process | ? { $_.Path -eq $rdpPath -and $_.CommandLine -like "*$rdpOptions*" } | % { Stop-Process -Id $_.ProcessId -Force }

    # Find mstsc processes again
    Write-Output "`nMSTSC PROCESSES AFTER STOP:"
    Write-Output $delimShort; Get-WmiObject Win32_Process | ? { $_.Path -eq $rdpPath } | Select-Object CommandLine, ProcessID, SessionID, CreationDate; Write-Output $delimShort

    Write-Output "`nCURRENT SESSIONS LIST:"
    Write-Output $delimShort; & $qwinstaPath; Write-Output $delimShort

    # Search for existing NON-RDP session (active CONSOLE or disconnected).
    # If found ==> reconnect to local RDP. If not found (i.e active RDP connection exists) ==> just exit.
    $nonRDPSessionCount = (((& $qwinstaPath $sessionUser 2>$null) -match " $sessionUser ") -notmatch " rdp" | Measure-Object -Line).Lines
    If ($nonRDPSessionCount -gt 0) {
      Write-Output "`nFOUND NON-RDP SESSION. STARTING LOCAL MSTSC ($rdpPath $rdpOptions)..."
      Start-Process -FilePath $rdpPath -ArgumentList $rdpOptions
      Start-Sleep -Seconds 1
      Write-Output "`nCURRENT SESSIONS LIST:"
      Write-Output $delimShort; & $qwinstaPath; Write-Output $delimShort
    }
    Else {
      Write-Output "`nNON-RDP SESSIONS NOT FOUND."
    }
  }
  ElseIf ($remoteControl -eq "teamviewer") {
    Write-Output "SWITCHING TO TeamViewer MODE..."

    # List current sessions 
    Write-Output "`nCURRENT SESSIONS LIST:"
    Write-Output $delimShort; & $qwinstaPath; Write-Output $delimShort

    # Search for existing NON-CONSOLE session (active RDP or disconnected).
    # If found ==> move session to CONSOLE. If not found ==> just exit.
    $nonConsoleSessionCount = (((& $qwinstaPath $sessionUser 2>$null) -match " $sessionUser ") -notmatch " console " | Measure-Object -Line).Lines
    If ($nonConsoleSessionCount -gt 0) {
      Write-Output "`nFOUND NON-CONSOLE SESSION. RECONNECTING TO CONSOLE..."
      $nonConsoleSessionID = (((((& $qwinstaPath 2>&1) | Select-String -Pattern "^.*$sessionUser[ ]+[0-9][0-9]*.*$") -split ("$sessionUser"))[1]) -split ("\s+"))[1]
      Write-Output "`nSESSION ID = $nonConsoleSessionID" 
      & $tsconPath $nonConsoleSessionID /dest:console /v
      Start-Sleep -Seconds 1
      Write-Output "`nCURRENT SESSIONS LIST:"
      Write-Output $delimShort; & $qwinstaPath; Write-Output $delimShort
    }
    Else {
      Write-Output "`nNON-CONSOLE SESSIONS NOT FOUND."
    }
  }
  Else {
    Write-Output "ERROR: Unknown value for 'remoteControl': `"$remoteControl`""
  }

  Write-Output "RestoreRDSession ended at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
  Write-Output $delimLong
} | Tee-Object -Append -FilePath $logPath
