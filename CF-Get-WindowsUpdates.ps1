$StartTime = Get-Date
$history = Get-WUHistory -Last 1000
$30days = (Get-Date).AddDays(-30)

#Filter Out results with Regex
$Result = $history | Sort-Object Date -desc |
  Select-Object -Property Date,KB,@{l='Category';e={[string]$_.Categories[0].Name}},Title,Result `
| Where-Object {$_.Title -notmatch "Security Intelligence Update for Microsoft Defender Antivirus \d*"}


$Lastreboot = Get-CimInstance -ClassName Win32_OperatingSystem
$LastrebootTime = $Lastreboot.LastBootUpTime
$lastupdate = $result.date | Select-Object -first 1

if ($lastupdate -lt $30days -or $LastrebootTime -lt $30days) {

    $Output = [pscustomobject][ordered]@{
        "Last Update Date" = $Result | Where-Object {$_.Date -lt $30days} | Select-Object -ExpandProperty Date -First 1 | Get-Date -Format "dddd dd/MM/yyyy HH:mm"
        "Last ReBoot" = $Lastreboot.LastBootUpTime | Get-Date -Format "dddd dd/MM/yyyy HH:mm"
        Status = "Critical-1001"
        "Update Status" = "Systeem niet volledig gepatched, graag z.s.m updaten"
        "Scan-Time" = "$((New-Timespan -Start $StartTime -End $(Get-Date)).TotalSeconds) seconds"
        "Last Installed-KB" = $Result | Where-Object {$_.date -lt $30days} | Select-Object -ExpandProperty KB -First 4 | Out-String

    }
}

else {

    $Output = [pscustomobject][ordered]@{
        "Last Update Date" = $Result | Where-Object {$_.Date -gt $30days} | Select-Object -ExpandProperty Date -First 1 | Get-Date -Format "dddd dd/MM/yyyy HH:mm"
        "Last ReBoot" = $Lastreboot.LastBootUpTime | Get-Date -Format "dddd dd/MM/yyyy HH:mm"
        Status = "Healthy-1000"
        "Update Status" = "Systeem volledig gepatched!"
        "Scan-Time" = "$((New-Timespan -Start $StartTime -End $(Get-Date)).TotalSeconds) seconds"
        "Last Installed-KB" = $Result | Where-Object {$_.date -gt $30days} | Select-Object -ExpandProperty KB -First 4 | Out-String

    }

    }


$Output = $Output | Format-List | Out-String


Ninja-Property-Set windowsUpdateStatus $Output

