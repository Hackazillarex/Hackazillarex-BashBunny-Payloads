$drivelabel = 'BashBunny'
$volume = Get-WmiObject win32_volume -Filter "label='$drivelabel'"

if ($volume) {
    # Define the specific output directory for WinPEAS
    $winpeasOutputDir = Join-Path -Path $volume.Name -ChildPath 'loot\WinPeas'
    $toolDirectory = Join-Path -Path $volume.Name -ChildPath 'tooling'

    # --- Step 1: Ensure the Loot Directory Exists ---
    if (-not (Test-Path $winpeasOutputDir)) {
        try {
            New-Item -Path $winpeasOutputDir -ItemType Directory -Force | Out-Null
            Write-Host "Created directory: $winpeasOutputDir"
        } catch {
            Write-Error "Failed to create directory '$winpeasOutputDir'. Error: $($_.Exception.Message)"
            exit 1
        }
    }

    # --- Step 2: Verify the Loot Directory is Writable ---
    $dummyFile = Join-Path -Path $winpeasOutputDir -ChildPath "writable_test.tmp"
    try {
        "test" | Out-File -FilePath $dummyFile -Encoding ASCII -Force
        if (Test-Path $dummyFile) {
            Remove-Item -Path $dummyFile -Force
            Write-Host "Successfully wrote to loot directory: $winpeasOutputDir"
        } else {
            Write-Error "Failed to create/remove test file in '$winpeasOutputDir'. Check permissions."
            exit 1
        }
    } catch {
        Write-Error "An error occurred while testing writability of '$winpeasOutputDir': $($_.Exception.Message)"
        exit 1
    }

    # Construct the full path to the WinPEAS executable
    $toolPath = Join-Path -Path $toolDirectory -ChildPath 'winPEASx64_ofs.exe'
    
    # Define the name of the final output file
    $outputFileName = "results.txt"
    $outputFile = Join-Path -Path $winpeasOutputDir -ChildPath $outputFileName

    if (Test-Path $toolPath) {
        Write-Host "WinPEAS executable found at: $toolPath"
        Write-Host "Attempting to run WinPEAS from '$toolDirectory' and save output to '$outputFile'."

        # --- Direct command execution with redirection ---
        # We will use cmd.exe to:
        # 1. Change directory to where winPEAS.exe is located.
        # 2. Execute winPEAS.exe.
        # 3. Redirect its standard output (and standard error) to the loot file.
        
        $cmdExePath = "cmd.exe"
        
        # Construct the full paths with quotes for safety
        $quotedToolDirectory = "`"$toolDirectory`""
        $quotedToolPath = "`"$toolPath`""
        $quotedOutputFile = "`"$outputFile`""
        
        # The command to be executed by cmd.exe:
        # "cd /d <ToolDirectory> && <ToolPath> > <OutputFile> 2>&1"
        # This ensures WinPEAS runs from its directory and outputs to the loot.
        $commandArgs = "/c ""cd /d $quotedToolDirectory && $quotedToolPath > $quotedOutputFile 2>&1"""

        Write-Host "Executing: $cmdExePath $commandArgs"

        try {
            # Execute the command. Using Start-Process with a specific working directory
            # might be redundant here since we're using 'cd' inside the command,
            # but it doesn't hurt and can sometimes help.
            $process = Start-Process -FilePath $cmdExePath -ArgumentList $commandArgs -WorkingDirectory $toolDirectory -WindowStyle Hidden -Wait -PassThru

            # Check if the output file was created and has content.
            if (Test-Path $outputFile) {
                $fileInfo = Get-Item $outputFile
                if ($fileInfo.Length -gt 0) {
                    Write-Host "WinPEAS executed successfully. Output saved to '$outputFile'."
                } else {
                    Write-Warning "WinPEAS executed, but the output file '$outputFile' is empty. It might have produced no output or encountered an internal error."
                }
            } else {
                Write-Error "WinPEAS execution was attempted, but the output file '$outputFile' was NOT created. Check for explicit errors in the console or any generated error files."
            }
            
            # Check process exit code for any issues
            if ($process.ExitCode -ne 0) {
                 Write-Warning "WinPEAS process exited with a non-zero code: $($process.ExitCode). This may indicate an error during execution."
            }

        } catch {
            Write-Error "An error occurred while trying to run WinPEAS via cmd.exe: $($_.Exception.Message)"
            exit 1
        }

    } else {
        Write-Error "WinPEAS executable not found at: $toolPath"
        exit 1
    }

} else {
    Write-Error "Drive labeled '$drivelabel' not found."
    exit 1
}
