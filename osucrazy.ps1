Add-Type -AssemblyName System.Windows.Forms

$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Icon = [System.Drawing.SystemIcons]::Application
$trayIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem "Exit"
$exitMenuItem.Add_Click({
    $trayIcon.Dispose()
    Stop-Process -Id $pid
})

$contextMenu.Items.Add($exitMenuItem)
$trayIcon.ContextMenuStrip = $contextMenu

$osuPath = "D:\osuscr0824\osu\osu.Desktop\bin\Debug\net8.0\"
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Users\Bodya\Downloads"
$watcher.Filter = "*.osz"
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'
$watcher.EnableRaisingEvents = $true
$fileTimers = @{}

$onCreated = {
    $filePath = $Event.SourceEventArgs.FullPath
	if (($filePath | Split-Path -Leaf).Length -lt 16) {
		Write-Host "File name is less than 16 characters, skipping: $filePath"
		return
	}
	Write-Host $filePath
    $job = Start-Job -ScriptBlock {
        param (
            [string]$filePath
        )
		$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
		while($stopwatch.Elapsed.TotalMilliseconds -lt 10000) { #ten secs
			$fileInfo = Get-Item -Path $filePath
			#Write-Host $fileInfo.Length
			if($fileInfo.Length -gt 0) {
				Write-Host "done"
				Start-Process cmd.exe -NoNewWindow -ArgumentList "/c osu!.exe `"$filePath`"" -WorkingDirectory "D:\osuscr0824\osu\osu.Desktop\bin\Debug\net8.0\"
				return
			}
			Start-Sleep -Milliseconds 100
		}

        #Write-Host "running: $filePath"
        Start-Process cmd.exe -NoNewWindow -ArgumentList "/c osu!.exe `"$filePath`"" -WorkingDirectory "D:\osuscr0824\osu\osu.Desktop\bin\Debug\net8.0\"
    } -ArgumentList $filePath
	#Wait-Job -Job $job
	#$output = Receive-Job -Job $job
	#Write-Host "File"
	#$output
}

Register-ObjectEvent $watcher Created -Action $onCreated

$signature = @"
using System;
using System.Runtime.InteropServices;

public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
Add-Type -TypeDefinition $signature
$hwnd = (Get-Process -Id $pid).MainWindowHandle
[WindowHelper]::ShowWindow($hwnd, 0) #"show" but actually hide

while ($trayIcon.Visible) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 100
}

$trayIcon.Dispose()
