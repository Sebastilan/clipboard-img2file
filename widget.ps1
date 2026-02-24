Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Test-MonitorRunning {
    $null -ne (Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
               Where-Object { $_.CommandLine -like '*clipboard-img2file*' })
}

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" Width="80" Height="40" ShowInTaskbar="False"
        ResizeMode="NoResize" Title="Clipboard Monitor">
    <Border CornerRadius="20" Background="#1e1e2e" Padding="8,6">
        <Border x:Name="Track" Width="52" Height="26" CornerRadius="13"
                Background="#555555" Cursor="Hand">
            <Ellipse x:Name="Thumb" Width="20" Height="20" Fill="White"
                     HorizontalAlignment="Left" VerticalAlignment="Center"
                     Margin="3,0,0,0"/>
        </Border>
    </Border>
</Window>
'@

$reader       = [System.Xml.XmlNodeReader]::new($xaml)
$script:win   = [Windows.Markup.XamlReader]::Load($reader)
$script:track = $script:win.FindName('Track')
$script:thumb = $script:win.FindName('Thumb')

$script:brushOn  = [Windows.Media.SolidColorBrush]([Windows.Media.Color]::FromRgb(0x22, 0xC5, 0x5E))
$script:brushOff = [Windows.Media.SolidColorBrush]([Windows.Media.Color]::FromRgb(0x55, 0x55, 0x55))
$script:brushOn.Freeze(); $script:brushOff.Freeze()

# Position: top-right corner
$wa = [Windows.SystemParameters]::WorkArea
$script:win.Left = $wa.Right - 92
$script:win.Top  = $wa.Top + 12

# Initial state
$script:isOn   = Test-MonitorRunning
$script:animPos = if ($script:isOn) { 29.0 } else { 3.0 }
$script:thumb.Margin   = [Windows.Thickness]::new($script:animPos, 0, 0, 0)
$script:track.Background = if ($script:isOn) { $script:brushOn } else { $script:brushOff }

# Smooth animation timer
$script:animTarget = $script:animPos
$script:animTimer  = [Windows.Threading.DispatcherTimer]::new()
$script:animTimer.Interval = [TimeSpan]::FromMilliseconds(12)
$script:animTimer.Add_Tick({
    $diff = $script:animTarget - $script:animPos
    if ([Math]::Abs($diff) -lt 0.5) {
        $script:animPos = $script:animTarget
        $script:animTimer.Stop()
    } else {
        $script:animPos += $diff * 0.25
    }
    $script:thumb.Margin = [Windows.Thickness]::new($script:animPos, 0, 0, 0)
})

# Toggle: suppress drag on track, handle click
$script:track.Add_MouseLeftButtonDown({ param($s,$e); $e.Handled = $true })
$script:track.Add_MouseLeftButtonUp({
    param($s, $e)
    $e.Handled = $true
    $script:isOn = -not $script:isOn
    $script:animTarget = if ($script:isOn) { 29.0 } else { 3.0 }
    $script:track.Background = if ($script:isOn) { $script:brushOn } else { $script:brushOff }
    $script:animTimer.Start()
    if ($script:isOn) {
        Start-ScheduledTask -TaskName 'ClipboardImg2File' -ErrorAction SilentlyContinue
    } else {
        Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like '*clipboard-img2file*' } |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        Stop-ScheduledTask -TaskName 'ClipboardImg2File' -ErrorAction SilentlyContinue
    }
})

# Drag on outer dark border
$script:win.Add_MouseLeftButtonDown({ $script:win.DragMove() })

# Right-click = exit widget
$script:win.Add_MouseRightButtonUp({ $script:win.Close() })

# Hover: fade in/out
$script:win.Opacity = 0.75
$script:win.Add_MouseEnter({ $script:win.Opacity = 1.0 })
$script:win.Add_MouseLeave({ $script:win.Opacity = 0.75 })

[void]$script:win.ShowDialog()
