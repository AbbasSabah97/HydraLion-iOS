# PowerShell 7 / Windows PowerShell 5.1; Git for Windows required.
# Pushes the COMPLETE project plus the six original mascot PNGs into a new branch.
param(
    [string]$Repository = "https://github.com/AbbasSabah97/WaterReminder.git",
    [string]$Branch = "feature/hydralion-ios-20261029"
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$project = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path (Join-Path $project 'HydraLion.xcodeproj/project.pbxproj'))) {
    throw 'The ZIP must be fully extracted before running PUSH-TO-GITHUB.ps1.'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Install Git for Windows (https://git-scm.com/downloads/win) and sign in to GitHub before running this script.'
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ("hydralion-" + [guid]::NewGuid().ToString('N'))
try {
    & git clone --depth 1 $Repository $temp
    if ($LASTEXITCODE -ne 0) { throw 'Git clone failed. Check repository access and credentials.' }
    Push-Location $temp
    try {
        & git switch -c $Branch
        if ($LASTEXITCODE -ne 0) { throw 'Branch creation failed.' }
        $destination = Join-Path $temp 'ios'
        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Copy-Item -Recurse -Force (Join-Path $project 'HydraLion') $destination
        Copy-Item -Recurse -Force (Join-Path $project 'HydraLion.xcodeproj') $destination
        Copy-Item -Force (Join-Path $project 'README.md') (Join-Path $destination 'README.md')
        New-Item -ItemType Directory -Force -Path (Join-Path $temp '.github/workflows') | Out-Null
        Copy-Item -Force (Join-Path $project '.github/workflows/ios-ipa.yml') (Join-Path $temp '.github/workflows/ios-ipa.yml')
        & git add ios .github/workflows/ios-ipa.yml
        if ($LASTEXITCODE -ne 0) { throw 'Git add failed.' }
        & git commit -m 'Add HydraLion SwiftUI water reminder iOS app and IPA workflow'
        if ($LASTEXITCODE -ne 0) { throw 'Commit failed. Configure git user.name and user.email if needed.' }
        & git push --set-upstream origin $Branch
        if ($LASTEXITCODE -ne 0) { throw 'Push failed. Verify your GitHub authentication and branch permissions.' }
        Write-Host 'Success! Go to GitHub Actions / HydraLion iOS IPA to check the build.'
        Write-Host 'Create a pull request if you want to merge the iOS app into main.'
    }
    finally { Pop-Location }
}
finally {
    if (Test-Path $temp) { Remove-Item -Recurse -Force $temp }
}
