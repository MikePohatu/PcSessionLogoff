
Function Get-LoggedOnUser
{
    <#
    .Synopsis
    Queries a computer to check for interactive sessions

    .DESCRIPTION
    This script takes the output from the quser program and parses this to PowerShell objects

    .NOTES   
    Name: Get-LoggedOnUser
    Author: Jaap Brasser
    Version: 1.2.1
    DateUpdated: 2015-09-23

    .LINK
    http://www.jaapbrasser.com

    .PARAMETER ComputerName
    The string or array of string for which a query will be executed

    .EXAMPLE
    .\Get-LoggedOnUser.ps1 -ComputerName server01,server02

    Description:
    Will display the session information on server01 and server02

    .EXAMPLE
    'server01','server02' | .\Get-LoggedOnUser.ps1

    Description:
    Will display the session information on server01 and server02
    #>

    param(
        [CmdletBinding()] 
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName = 'localhost'
    )
    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        [System.Collections.ArrayList]$sessions = New-Object System.Collections.ArrayList

        foreach ($Computer in $ComputerName) {
            try {
                quser /server:$Computer 2>&1 | Select-Object -Skip 1 | ForEach-Object {
                    $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
                    $HashProps = @{
                        UserName = $CurrentLine[0]
                        ComputerName = $Computer
                    }

                    # If session is disconnected different fields will be selected
                    if ($CurrentLine[2] -eq 'Disc') {
                            $HashProps.SessionName = $null
                            $HashProps.Id = $CurrentLine[1]
                            $HashProps.State = $CurrentLine[2]
                            $HashProps.IdleTime = $CurrentLine[3]
                            $HashProps.LogonTime = $CurrentLine[4..6] -join ' '
                            $HashProps.LogonTime = $CurrentLine[4..($CurrentLine.GetUpperBound(0))] -join ' '
                    } else {
                            $HashProps.SessionName = $CurrentLine[1]
                            $HashProps.Id = $CurrentLine[2]
                            $HashProps.State = $CurrentLine[3]
                            $HashProps.IdleTime = $CurrentLine[4]
                            $HashProps.LogonTime = $CurrentLine[5..($CurrentLine.GetUpperBound(0))] -join ' '
                    }

                    $session = New-Object -TypeName PSCustomObject -Property $HashProps |
                        Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
                    $sessions.Add($session)
                } 
            } catch {
                $session = New-Object -TypeName PSCustomObject -Property @{
                    ComputerName = $Computer
                    Error = $_.Exception.Message
                } | Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
                $sessions.Add($session)
            }
        }

        return $sessions
    }
}


Function Get-IdleUsers
{
    Param ([int]$idleminutes=1440)

    begin {
        [System.Collections.ArrayList]$idleusers = New-Object System.Collections.ArrayList
    }

    process {
        Get-LoggedOnUser | ForEach-Object {
            if (($_.IdleTime -gt $idleminutes) -AND ($_.State -ne "Active"))
            {
                $idleusers.Add($_)
            }
        }
        return $idleusers
    }
}


Function Get-ActiveUsers
{
    [System.Collections.ArrayList]$activeusers = New-Object System.Collections.ArrayList

    Get-LoggedOnUser | ForEach-Object {
        if ($_.State -eq "Active")
        {
            $activeusers.Add($_)
        }  
    }

    return $activeusers
}


function LogoffComputerSessionId {
    param(
        [CmdletBinding()] 
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$Id,
        [CmdletBinding()] 
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName
    )

    process {
        logoff $Id /server:$ComputerName
    }
}


Get-ActiveUsers
