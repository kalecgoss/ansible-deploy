# set prompt
function prompt {
  $ESC = [char]27
  "$ESC[33;1mPS$ESC[0m $ESC[31;1m$ENV:USERNAME@$ENV:COMPUTERNAME$ESC[0m $ESC[36;1m$($executionContext.SessionState.Path.CurrentLocation)$ESC[0m$('>' * ($nestedPromptLevel + 1))"
}

# 'uptime' command
function uptime {
  ((Get-Date)-(Get-WmiObject Win32_OperatingSystem | % {$_.ConvertToDateTime($_.LastBootUpTime)})) | % {"Uptime: "+$_.Days+" day(s) "+$_.Hours+":"+$_.Minutes+":"+$_.Seconds}
}

# 'pkgs' command, get list of installed software
function pkgs {
  Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
}

# 'lpd' command, get list of ldplayer processes
function ldp {
  Get-Process | ? {$_.Name -like "*ld*"}
}

# start AIDA64 hardware test
function AIDA64-RunTest {
  Write-Host "Starting 30min system stability test..."
  schtasks.exe /run /tn "AIDA64-RunTest"
}

# stop AIDA64 hardware test
function AIDA64-StopTest {
  Get-Process | ? {$_.Path -like "C:\Program Files\AIDA64*"} | Stop-Process -Force
  Start-Sleep 5
  Remove-Item -Path "C:\Users\{{ ansible_user }}\AppData\Local\Temp\sst-is-running.txt" -Force -ErrorAction SilentlyContinue
  Remove-Item -Path "C:\`$`$`$ AIDA64 Disk Stress Test Temporary File `$`$`$.`$`$`$" -Force -ErrorAction SilentlyContinue
  Write-Host "AIDA64 processes were killed. Please, run ntop to check system load."
}

# start VICTORIA test
function Victoria-RunTest {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(0,1)]
    [int]$Disk
  )
  $path = "C:\ProgramData\chocolatey\lib\victoria\tools\Victoria.ini"
  $victoriaProcess = Get-Process | ? {$_.Name -like "*victoria*"}
  If ($null -ne $victoriaProcess) {
    Write-Host "Process $($victoriaProcess.Name) is already working!"
    Write-Host "Use command 'Victoria-StopTest' to end the test."
  } Else {
    Write-Host "Run test on disk $($Disk) ..."
    
    (Get-Content $path) -replace "^Last API device=\d", "Last API device=$($Disk)" |`
    Set-Content -Encoding ASCII -Path $path

    Start-Sleep 2
    schtasks.exe /run /tn "VICTORIA-RunTest"
  }
}

# stop VICTORIA test
function Victoria-StopTest {
  Get-Process | ? {$_.Path -like "C:\ProgramData\chocolatey\lib\victoria\tools\*"} | Stop-Process -Force
  Start-Sleep 3
  Write-Host "Victoria was stopped"
}

# 'reboot' command
function reboot {
  Restart-Computer -Force
}

# enable session close with Ctrl+D
Set-PSReadlineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

# disable progress-bar to speed up 'Invoke-WebRequest' cmdlet
$ProgressPreference="SilentlyContinue"

# _very_ simple 'tail' / 'tail -f' versions
function tail {
  param (
    [Parameter(Mandatory = $false)] [switch]$f,
    [Parameter(Mandatory = $true)] [string]$path
  )
  $lines = 100
  If ($f.IsPresent) {
    Get-Content -Path $path -Tail $lines -Wait
  }
  Else {
    Get-Content -Path $path -Tail $lines
  }
}

# short command to start Far Manager
function far {
  & "C:\Program Files\Far Manager\Far.exe" C:\Users\{{ ansible_user }}
}

# short command to show errors from system eventlog
function Get-EventLogErrors {
  Get-EventLog -LogName "System" -EntryType "Error"
}

# function to show disk space
function df {
  Get-WmiObject -Class Win32_LogicalDisk | `
  Select-Object -Property DeviceID, VolumeName, `
  @{
    Label='FreeSpace (Gb)'; Expression={($_.FreeSpace/1GB).ToString('F2')}
  }, `
  @{
    Label='Total (Gb)'; Expression={($_.Size/1GB).ToString('F2')}
  }, `
  @{
    Label='FreePercent'; Expression={[Math]::Round(($_.FreeSpace / $_.Size) * 100, 2)}
  }
}

# set aliases
Set-Alias -Name vi -Value vim
Set-Alias -Name htop -Value ntop
Set-Alias -Name dn -Value dnconsole
Set-Alias -Name errors -Value Get-EventLogErrors
