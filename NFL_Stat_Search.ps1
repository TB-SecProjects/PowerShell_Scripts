function Show-Menu {
    param (
        [string]$Title,
        [string[]]$Options
    )
    Write-Host "------------------------"
    Write-Host $Title
    Write-Host "------------------------"
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host "$($i + 1). $($Options[$i])"
    }
    Write-Host "------------------------"
}

function Get-TeamRecord {
    param (
        [string]$TeamId,
        [string]$TeamName,
        [string]$Season
    )

    $recordApiUrl = "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/$Season/types/2/teams/$TeamId/record"

    try {
        # Make the API call to fetch team record data
        $response = Invoke-WebRequest -Uri $recordApiUrl -Method Get
        
        # Parse the response body as JSON
        $data = $response.Content | ConvertFrom-Json

        if ($data -and $data.items) {
            Write-Host "------------------------"
            Write-Host "$TeamName Record:"
            Write-Host "------------------------"
            
            # Iterate through the items to find the 'overall' record
            foreach ($item in $data.items) {
                if ($item.name -eq 'overall') {
                    Write-Host "Overall Record: $($item.summary)"
                    break
                }
            }
        } else {
            Write-Host "No team record data available."
        }
    }
    catch {
        Write-Host "Failed to retrieve team record. Error: $_"
    }
}

function Get-TeamRoster {
    param (
        [string]$TeamId,
        [string]$TeamName
    )

    $rosterApiUrl = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/$TeamId/roster"

    try {
        # Make the API call to fetch team roster data
        $response = Invoke-WebRequest -Uri $rosterApiUrl -Method Get
        
        # Parse the response body as JSON
        $data = $response.Content | ConvertFrom-Json

        if ($data -and $data.athletes) {
            Write-Host "------------------------"
            Write-Host "$TeamName Roster:"
            Write-Host "------------------------"
            
            # Create a list to hold player details
            $roster = @()

            # Iterate through the athletes to collect player information
            foreach ($athlete in $data.athletes) {
                foreach ($player in $athlete.items) {
                    $roster += [PSCustomObject]@{
                        Name        = $player.displayName
                        Number      = $player.jersey
                        Position    = $player.position.displayName
                    }
                }
            }

            # Display the roster in a table format
            if ($roster.Count -gt 0) {
                $roster | Format-Table -AutoSize
            } else {
                Write-Host "No roster data available."
            }
        } else {
            Write-Host "No roster data available."
        }
    }
    catch {
        Write-Host "Failed to retrieve team roster. Error: $_"
    }
}

function Get-TeamSchedule {
    param (
        [string]$TeamId,
        [string]$TeamName,
        [string]$SeasonYear
    )

    # Construct the API URL with the season year
    $scheduleApiUrl = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/$TeamId/schedule?season=$SeasonYear"

    try {
        # Make the API call to fetch team schedule data
        $response = Invoke-WebRequest -Uri $scheduleApiUrl -Method Get

        # Parse the response body as JSON
        $data = $response.Content | ConvertFrom-Json

        # Check if the 'events' array is present and not null
        if ($data -and $data.events -and $data.events.Count -gt 0) {
            Write-Host "------------------------"
            Write-Host "$TeamName Schedule:"
            Write-Host "------------------------"
            
            # Create a list to hold game details
            $schedule = @()

            # Iterate through the events to collect game information
            foreach ($event in $data.events) {
                # Determine if the game is home or away
                $homeTeam = $event.competitions[0].competitors | Where-Object { $_.homeAway -eq 'home' }
                $awayTeam = $event.competitions[0].competitors | Where-Object { $_.homeAway -eq 'away' }
                
                # Ensure home and away teams are correctly identified
                if ($homeTeam -and $awayTeam) {
                    $isHome = ($homeTeam.team.id -eq $TeamId)
                    $opponent = if ($isHome) { $awayTeam.team.displayName } else { $homeTeam.team.displayName }
                    $homeOrAway = if ($isHome) { "Home" } else { "Away" }

                    # Convert the event date to desired format
                    $eventDate = [datetime]::Parse($event.date)
                    $formattedDateTime = $eventDate.ToString("MM-dd-yyyy hh:mm tt")

                    $schedule += [PSCustomObject]@{
                        DateTime     = $formattedDateTime
                        Opponent     = $opponent
                        HomeOrAway   = $homeOrAway
                        Week         = $event.week.text
                    }
                }
            }

            # Display the schedule in a table format
            if ($schedule.Count -gt 0) {
                $schedule | Format-Table -AutoSize
            } else {
                Write-Host "No games found in the schedule."
            }
        } else {
            Write-Host "No schedule data available or structure has changed."
        }
    }
    catch {
        Write-Host "Failed to retrieve team schedule. Error: $_"
    }
}


function Get-TeamId {
    param (
        [string]$ApiUrl,
        [string]$SearchTeamName
    )

    try {
        # Make the API call to fetch team data
        $response = Invoke-WebRequest -Uri $ApiUrl -Method Get
        
        # Parse the response body as JSON
        $data = $response.Content | ConvertFrom-Json

        # Access the 'teams' array within the 'leagues' array
        $teams = $data.sports[0].leagues[0].teams

        if ($teams) {
            foreach ($team in $teams) {
                # Access the nested 'team' object
                $teamInfo = $team.team
                
                # Normalize case and trim whitespace
                $teamName = $teamInfo.displayName.Trim().ToLower()
                $searchName = $SearchTeamName.Trim().ToLower()

                if ($teamName -eq $searchName) {
                    return $teamInfo.id
                }
            }
        }
    }
    catch {
        Write-Host "Failed to retrieve team ID. Error: $_"
    }

    return $null
}

function Show-TeamOptionsMenu {
    param (
        [string]$ApiUrl,
        [string]$TeamId,
        [string]$TeamName
    )

    $options = @("View Team Record", "View Team Roster", "View Team Schedule", "Search for a Different Team", "Return to Main Menu", "Exit")

    while ($true) {
        Show-Menu -Title "Team Options" -Options $options
        $selection = Read-Host "Please select a number"

        switch ($selection) {
            1 {
                $season = Read-Host "Enter the season (e.g., 2024)"
                Get-TeamRecord -TeamId $TeamId -TeamName $TeamName -Season $season
            }
            2 {
                Get-TeamRoster -TeamId $TeamId -TeamName $TeamName
            }
            3 {
                $seasonYear = Read-Host "Enter the season year (e.g., 2024)"
                Get-TeamSchedule -TeamId $TeamId -TeamName $TeamName -SeasonYear $seasonYear
            }
            4 {
                return
            }
            5 {
                return Main-Menu
            }
            6 {
                exit
            }
            default {
                Write-Host "Invalid selection. Please try again."
            }
        }
    }
}

function Show-TeamSearchMenu {
    param (
        [string]$ApiUrl
    )

    while ($true) {
        # Get the team name from the user
        $teamName = Read-Host "Enter the team name you want to search for"
        
        # Fetch the team data to get the team ID
        $teamId = Get-TeamId -ApiUrl $ApiUrl -SearchTeamName $teamName
        
        if ($teamId) {
            # Call the function to show team options menu
            Show-TeamOptionsMenu -ApiUrl $ApiUrl -TeamId $teamId -TeamName $teamName
        }
        else {
            Write-Host "Team '$teamName' not found."
        }
    }
}

function Main-Menu {
    $mainOptions = @("Search Team Stats", "Search Player Stats", "Exit")
    $apiUrl = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams'

    while ($true) {
        Show-Menu -Title "NFL Stat Search" -Options $mainOptions
        $selection = Read-Host "Please select a number"

        switch ($selection) {
            1 {
                # Call the function to search for a team
                Show-TeamSearchMenu -ApiUrl $apiUrl
            }
            2 {
                # Code for Option 2 (Player Stats)
                Write-Host "Player Stats functionality is not implemented yet."
                # Add code for Player Stats here if needed
            }
            3 {
                # Exit the script
                Write-Host "Exiting..."
                exit
            }
            default {
                Write-Host "Invalid selection. Please try again."
            }
        }
    }
}

# Start the main menu
Main-Menu
