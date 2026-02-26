param(
    [string]$DefaultMessage = "Claude Code"
)
$rawInput = @($input) -join "`n"
$hookData = $rawInput | ConvertFrom-Json
$message = $hookData.message
if (-not $message) { $message = $DefaultMessage }

$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$iconPath = (Resolve-Path (Join-Path $scriptDir "..\assets\icon.png") -ErrorAction SilentlyContinue).Path
$toastXml = @"
<toast duration="short">
  <visual>
    <binding template="ToastGeneric">
      <text>Claude</text>
      <text>$message</text>
      <image placement=`"appLogoOverride`" src=`"file:///$($iconPath -replace '\\','/')`"/>
    </binding>
  </visual>
  <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
"@

$xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
$xml.LoadXml($toastXml)
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($toast)
