Import-Module PcSessionManagement

New-TimeSpan -minutes 15 | Get-IdleUsers  | ForEach-Object { LogoffComputerSessionId -Id $_.Id -ComputerName $_.ComputerName }