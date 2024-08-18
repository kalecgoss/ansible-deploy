# Stop all VNC processes at first
Get-Process | ?{$_.Name -eq "vnc"} | Stop-Process -Force

# If VNC exits, PowerShell will start it again.
while ($true) {
  Start-Process -FilePath "C:\Program Files\RealVNC\VNC Server\vncserver.exe" -Wait -WindowStyle Hidden
  Start-Sleep 1
}
