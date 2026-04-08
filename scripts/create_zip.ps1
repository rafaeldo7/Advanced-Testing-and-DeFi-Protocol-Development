# Create ZIP for submission
# Run this script to package all deliverables

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$zipName = "Assignment2_Submission_$timestamp.zip"

# Files and directories to include
$items = @(
    "src",
    "test", 
    "script",
    "docs",
    "foundry.toml",
    "remappings.txt",
    "README.md",
    ".gitmodules"
)

# Create zip
Compress-Archive -Path $items -DestinationPath $zipName -Force

Write-Host "Created: $zipName"
Write-Host "Contents:"
Get-ChildItem $zipName | Format-Table Name, Length
