# Ninja-CF-Monitor-WindowsUpdates
Monitor Windows Updates in Ninja Custom Fields

Requirement is the use of "PSWindowsupdate" Module First itteration of the script was based on using the ComObject "Microsoft.Update.Session"
Witch the in return the PSWindowsupdate module also uses with the Get-WUHistory command.
Script is still work in progress but what i've see so far testing on different servers in our environment it looks quite accurrate.

The underlying part in the code filters out the Defender Antivirus updates, otherwise the last patch update would be always compliants since this updates multiple times per day.

`
#Filter Out results with Regex
$Result = $history | Sort-Object Date -desc |
  Select-Object -Property Date,KB,@{l='Category';e={[string]$_.Categories[0].Name}},Title,Result `
| Where-Object {$_.Title -notmatch "Security Intelligence Update for Microsoft Defender Antivirus \d*"}
`