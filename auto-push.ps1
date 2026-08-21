$folder = "C:\Users\Administrator\Desktop\farmlink"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $folder
$watcher.IncludeSubdirectories = $true
$watcher.Filter = "*.*"
$watcher.EnableRaisingEvents = $true

$action = {
    Start-Sleep -Seconds 2

    Set-Location "C:\Users\Administrator\Desktop\farmlink"

    git add .
    git commit -m "Auto update"
    git push
}

Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Created" -Action $action

Write-Host "Auto-push is running. Press Ctrl+C to stop."

while ($true) {
    Start-Sleep -Seconds 10
}