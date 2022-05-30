function Convert-WuaResultCodeToName {
    param( [Parameter(Mandatory=$true)]
    [int] $ResultCode
    )
$Result = $ResultCode
    switch($ResultCode){
    2
{
    $Result = "Succeeded"
}
    3
{
    $Result = "Succeeded With Errors"
}
    4
{
    $Result = "Failed"
}
}
    return $Result
}

function Get-WuaHistory {
    # Get a WUA Session
    $session = (New-Object -ComObject 'Microsoft.Update.Session')
    # Query the latest 1000 History starting with the first recordp
    $history = $session.QueryHistory("",0,50) | ForEach-Object {
    $Result = Convert-WuaResultCodeToName -ResultCode $_.ResultCode
    # Make the properties hidden in com properties visible.
    $_ | Add-Member -MemberType NoteProperty -Value $Result -Name Result
    $Product = $_.Categories | Where-Object {$_.Type -eq 'Product'} | Select-Object -First 1 -ExpandProperty Name
    $_ | Add-Member -MemberType NoteProperty -Value $_.UpdateIdentity.UpdateId -Name UpdateId
    $_ | Add-Member -MemberType NoteProperty -Value $_.UpdateIdentity.RevisionNumber -Name RevisionNumber
    $_ | Add-Member -MemberType NoteProperty -Value $Product -Name Product -PassThru
    Write-Output $_
    }
    #Remove null records and only return the fields we want
    $history | Where-Object {![String]::IsNullOrWhiteSpace($_.title) `
        -and $_.title -notmatch "Security Intelligence Update for Microsoft Defender Antivirus \d*" `
        -and $_.Title -notmatch "Update for Microsoft Defender Antivirus antimalware platform \d*" `
        -and $_.Title -notmatch "Windows Malicious Software Removal Tool \d*"

    } | Select-Object Result, Date, Title, SupportUrl, Product, UpdateId, RevisionNumber
}

$StartTime = Get-Date
$30days = (Get-Date).AddDays(-30)

$Result = Get-WuaHistory

$Lastreboot = Get-CimInstance -ClassName Win32_OperatingSystem
$LastrebootTime = $Lastreboot.LastBootUpTime
$lastupdate = $result.date | Select-Object -first 1

if ($lastupdate -lt $30days -or $LastrebootTime -lt $30days) {

    $Output = [pscustomobject][ordered]@{
        "Last Update Date" = $Result | Where-Object {$_.Date -lt $30days} | Select-Object -ExpandProperty Date -First 1 | Get-Date -Format "dddd dd/MM/yyyy HH:mm"
        "Last Reboot" = $Lastreboot.LastBootUpTime | Get-Date -Format "dddd dd/MM/yyyy HH:mm"
        Status = "Critical-1001"
        "Update Status" = "System not fully patched, please update a.s.a.p"
        "Scan-Time" = "$((New-Timespan -Start $StartTime -End $(Get-Date)).TotalSeconds) seconds"
        "Build-ID" = (Get-ItemProperty -Path c:\windows\system32\hal.dll).VersionInfo.ProductVersion


    }
}

else {

    $Output = [pscustomobject][ordered]@{
        "Last Update Date" = $Result | Where-Object {$_.Date -gt $30days} | Select-Object -ExpandProperty Date -First 1 | Get-Date -Format "dddd dd/MM/yyyy HH:mm"
        "Last Reboot" = $Lastreboot.LastBootUpTime | Get-Date -Format "dddd dd/MM/yyyy HH:mm"
        Status = "Healthy-1000"
        "Update Status" = "System Fully Patched!"
        "Scan-Time" = "$((New-Timespan -Start $StartTime -End $(Get-Date)).TotalSeconds) seconds"
        "Build-ID" = (Get-ItemProperty -Path c:\windows\system32\hal.dll).VersionInfo.ProductVersion


    }

    }


$Output = $Output | Format-List | Out-String

$Output

Ninja-Property-Set windowsUpdateStatus $Output