$script:apps = @{
    "Mozilla Firefox" = "Mozilla.Firefox";
    "Spotify" = "Spotify.Spotify";
    "Steam" = "Valve.Steam";
    "Microsoft Visual Studio Code" = "Microsoft.VisualStudioCode";
    "JetBrains Toolbox" = "JetBrains.Toolbox";
    "Nvidia GeForce Experience" = "Nvidia.GeForceExperience";
    "Mozilla Thunderbird" = "Mozilla.Thunderbird";
    "ShareX" = "ShareX.ShareX";
    "HandBrake" = "HandBrake.HandBrake";
    "Git" = "Git.Git";
    "NodeJS" = "OpenJS.NodeJS";
}

function Confirm {
    Write-Host "Do you want to continue? (y/yes) or (n/no)" -ForegroundColor Yellow
    $confirmation = Read-Host
    if ($confirmation -eq 'y' -or $confirmation -eq 'yes') { return $true }
    Write-Host "Action aborted." -ForegroundColor Red
    return $false
}

function Pause {
    Write-Host "Press any key to continue..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") > $null
}

function Install {
    Write-Host "Attempting to install the following packages:" -ForegroundColor Green
    $script:apps.Keys | ForEach-Object { Write-Host ("- " + $_) }
    if (Confirm) {
        foreach ($appName in $script:apps.Keys) {
            $appID = $script:apps[$appName]
            winget install -e --id $appID
            if ($LASTEXITCODE -eq 0) {
                Write-Host ($appName + " installed successfully.") -ForegroundColor Green
            } else {
                Write-Host ("Failed to install " + $appName) -ForegroundColor Red
            }
        }
        Write-Host "All done." -ForegroundColor Green
    }
    Pause
}

function Uninstall {
    Write-Host "Attempting to uninstall the following packages:" -ForegroundColor Red
    $script:apps.Keys | ForEach-Object { Write-Host ("- " + $_) }
    if (Confirm) {
        foreach ($appName in $script:apps.Keys) {
            $appID = $script:apps[$appName]
            winget uninstall --id $appID
            if ($LASTEXITCODE -eq 0) {
                Write-Host ($appName + " initiated uninstall.") -ForegroundColor Green
            } else {
                Write-Host ("Failed to uninstall " + $appName) -ForegroundColor Red
            }

            $spinner = '|','/','-','\'
            $i = 0
            foreach ($iteration in 1..20) {
                $spinChar = $spinner[$i % 4]
                Write-Host "`b$spinChar" -NoNewline -ForegroundColor Blue
                Start-Sleep -Milliseconds 500
                $i++
            }
            Write-Host "`b "
        }
        Write-Host "All done." -ForegroundColor Green
    }
    Pause
}

function Add {
    while ($true) {
        Write-Host "Search for a package:" -ForegroundColor Yellow
        $query = Read-Host
        $result = winget search $query | Out-String
        Write-Host "Search results:" -ForegroundColor Green
        Write-Host $result
        Write-Host "Enter the package name you want to add:" -ForegroundColor Yellow
        $packageName = Read-Host
        Write-Host "Enter the package ID you want to add:" -ForegroundColor Yellow
        $packageID = Read-Host
        $script:apps.Add($packageName, $packageID)
        Write-Host ("Added " + $packageName + " with ID " + $packageID) -ForegroundColor Green
        Write-Host "Do you want to add another package? (y/yes) or (n/no)" -ForegroundColor Yellow
        $confirmation = Read-Host
        if ($confirmation -eq 'n' -or $confirmation -eq 'no') { break }
    }
    Pause
}

function Remove {
    $removedApps = @()
    Write-Host "Choose packages to remove:" -ForegroundColor Yellow
    $counter = 1
    $keys = $script:apps.Keys | Sort-Object
    $keys | ForEach-Object { Write-Host ("$counter - " + $_); $counter++ }
    $selection = Read-Host
    $indices = $selection -split ","
    foreach ($index in $indices) {
        $index = [int]$index - 1
        if ($index -ge 0 -and $index -lt $keys.Count) {
            $selectedAppName = $keys[$index]
            $script:apps.Remove($selectedAppName)
            $removedApps += $selectedAppName
        } else {
            Write-Host ("Invalid selection for index " + ($index + 1)) -ForegroundColor Red
        }
    }
    Write-Host "Removed packages:" -ForegroundColor Green
    $removedApps | ForEach-Object { Write-Host ("- " + $_) }
    Pause
}

function Export {
    $jsonContent = $script:apps | ConvertTo-Json
    Set-Content -Path "win-auto.json" -Value $jsonContent
    Write-Host "Exported to win-auto.json" -ForegroundColor Green
    Pause
}

function Import {
    $jsonContent = Get-Content -Path "win-auto.json"
    $tempObj = $jsonContent | ConvertFrom-Json
    $script:apps = @{}
    $tempObj.PSObject.Properties | ForEach-Object { $script:apps[$_.Name] = $_.Value }
    Write-Host "Imported from win-auto.json" -ForegroundColor Green
    Pause
}

while ($true) {
    Write-Host "Please choose an option:" -ForegroundColor Cyan
    Write-Host "1 - Install packages"
    Write-Host "2 - Uninstall packages"
    Write-Host "3 - Add package(s)"
    Write-Host "4 - Remove package(s)"
    Write-Host "5 - Export apps to json file"
    Write-Host "6 - Import apps from json file"
    Write-Host "7 - Exit"
    
    $response = Read-Host
    switch ($response) {
        "1" { Install }
        "2" { Uninstall }
        "3" { Add }
        "4" { Remove }
        "5" { Export }
        "6" { Import }
        "7" {
            Write-Host "Exiting." -ForegroundColor Red
            exit
        }
        default {
            Write-Host "Invalid option. Please choose between 1 to 7." -ForegroundColor Red
            Pause
        }
    }
    Clear-Host
}
