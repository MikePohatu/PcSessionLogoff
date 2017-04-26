Import-Module .\PcSessionManagement.psm1

$count = 0
Get-IdleUsers  | ForEach-Object { $count++ }

Write-Output $count