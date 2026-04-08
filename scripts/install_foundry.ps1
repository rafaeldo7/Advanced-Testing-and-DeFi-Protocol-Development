# Install Foundry (Forge)
# Run this script to install Foundry on Windows

Write-Host "Installing Foundry..."

# Create bin directory
$binDir = "$env:USERPROFILE\.foundry\bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

# Download latest Windows build
$releaseUrl = "https://api.github.com/repos/foundry-rs/foundry/releases/latest"
$response = Invoke-RestMethod -Uri $releaseUrl
$asset = $assets = $response.assets | Where-Object { $_.name -match "windows.*amd64.*zip" }

if ($asset) {
    Write-Host "Downloading $($asset.name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "foundry.zip"
    
    # Extract
    Write-Host "Extracting..."
    Expand-Archive -Path foundry.zip -DestinationPath $binDir -Force
    
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$binDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$binDir", "User")
        Write-Host "Added to PATH. Please restart your terminal."
    }
    
    Write-Host "Installation complete!"
    & "$binDir\forge.exe" --version
} else {
    Write-Host "Could not find Windows binary. Please download manually from GitHub."
}
