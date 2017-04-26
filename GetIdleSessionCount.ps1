Import-Module .\PcSessionManagement.psm1

$count = 0
New-TimeSpan -hours 4| Get-IdleUsers  | ForEach-Object { $count++ }

Write-Output $count