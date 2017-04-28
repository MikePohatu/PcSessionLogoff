Import-Module .\PcSessionManagement.psm1

New-TimeSpan -days 9 | Get-IdleUsers  | ForEach-Object { LogoffComputerSessionId -Id $_.Id -ComputerName $_.ComputerName }