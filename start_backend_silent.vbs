Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""Set-Location 'd:\Flutter projects\jobwink\backend'; python backend_main.py""", 0, False
