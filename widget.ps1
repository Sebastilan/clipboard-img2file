Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Test-MonitorRunning {
    $null -ne (Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
               Where-Object { $_.CommandLine -like '*clipboard-img2file*' -and
                              $_.CommandLine -notlike '*widget*' })
}

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" Width="32" Height="32" ShowInTaskbar="False"
        ResizeMode="NoResize" WindowStartupLocation="CenterScreen">
    <Border Background="#01000000" CornerRadius="4">
        <TextBlock x:Name="Lbl"
                   Text="&#xE8C8;"
                   FontFamily="Segoe MDL2 Assets"
                   FontSize="18"
                   Foreground="#2e4a6a"
                   HorizontalAlignment="Center"
                   VerticalAlignment="Center"
                   Cursor="Hand"/>
    </Border>
</Window>
'@

$reader     = [System.Xml.XmlNodeReader]::new($xaml)
$script:win = [Windows.Markup.XamlReader]::Load($reader)
$script:lbl = $script:win.FindName('Lbl')

$colorOff = '#2e4a6a'   # 暗蓝，黑底可见
$colorOn  = '#22c55e'   # 亮绿

# Restore saved position
$posFile = "$env:LOCALAPPDATA\clipboard-img2file\widget-pos.txt"
if (Test-Path $posFile) {
    try {
        $c = (Get-Content $posFile -Raw).Trim().Split(',')
        $script:win.Left = [double]$c[0]
        $script:win.Top  = [double]$c[1]
        $script:win.WindowStartupLocation = 'Manual'
    } catch { }
}

# Initial state
$script:isOn = Test-MonitorRunning
$script:lbl.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString(
    $(if ($script:isOn) { $colorOn } else { $colorOff }))

# Drag vs click detection
$script:downPos  = $null
$script:downTime = $null

$script:win.Add_MouseLeftButtonDown({
    param($s, $e)
    $script:downPos  = $e.GetPosition($script:win)
    $script:downTime = [DateTime]::Now
    $script:win.CaptureMouse() | Out-Null
})

$script:win.Add_MouseMove({
    param($s, $e)
    if ($script:downPos -ne $null -and $e.LeftButton -eq 'Pressed') {
        $p = $e.GetPosition($script:win)
        $d = [Math]::Sqrt(($p.X - $script:downPos.X)*($p.X - $script:downPos.X) +
                          ($p.Y - $script:downPos.Y)*($p.Y - $script:downPos.Y))
        if ($d -gt 5) {
            $script:downPos = $null
            $script:win.ReleaseMouseCapture() | Out-Null
            $script:win.DragMove()
            "$($script:win.Left),$($script:win.Top)" | Set-Content $posFile -NoNewline
        }
    }
})

$script:win.Add_MouseLeftButtonUp({
    param($s, $e)
    $script:win.ReleaseMouseCapture() | Out-Null
    if ($script:downPos -eq $null) { return }
    if (([DateTime]::Now - $script:downTime).TotalMilliseconds -gt 600) { $script:downPos = $null; return }

    $script:downPos = $null
    $script:isOn = -not $script:isOn
    $script:lbl.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString(
        $(if ($script:isOn) { $colorOn } else { $colorOff }))

    if ($script:isOn) {
        Start-ScheduledTask -TaskName 'ClipboardImg2File' -ErrorAction SilentlyContinue
    } else {
        Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like '*clipboard-img2file*' -and
                          $_.CommandLine -notlike '*widget*' } |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        Stop-ScheduledTask -TaskName 'ClipboardImg2File' -ErrorAction SilentlyContinue
    }
})

$script:win.Add_MouseRightButtonUp({ $script:win.Close() })

[void]$script:win.ShowDialog()
