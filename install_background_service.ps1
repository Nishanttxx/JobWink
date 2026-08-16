$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "JobWinkBackend.lnk"
$WScript = New-Object -ComObject WScript.Shell
$Shortcut = $WScript.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "wscript.exe"
$Shortcut.Arguments = ' "d:\Flutter projects\jobwink\start_backend_silent.vbs"'
$Shortcut.WorkingDirectory = "d:\Flutter projects\jobwink\backend"
$Shortcut.Save()
Write-Host "Successfully added JobWink Backend to Windows Startup! The backend will now start automatically whenever your PC boots." -ForegroundColor Green
