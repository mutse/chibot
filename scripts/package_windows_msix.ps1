#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-PubspecVersionInfo {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $content = Get-Content -Path $Path -Raw
  $match = [regex]::Match($content, '(?m)^\s*version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?\s*$')

  if (-not $match.Success) {
    throw "Could not find a valid pubspec version in $Path."
  }

  $baseVersion = $match.Groups[1].Value
  $buildNumber = if ($match.Groups[2].Success) { [int]$match.Groups[2].Value } else { 0 }

  return @{
    BaseVersion = $baseVersion
    BuildNumber = $buildNumber
    MsixVersion = "$baseVersion.$buildNumber"
  }
}

function Get-MsixVersion {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$PubspecVersion
  )

  if ($env:GITHUB_REF_TYPE -eq "tag" -and $env:GITHUB_REF_NAME) {
    $tagMatch = [regex]::Match($env:GITHUB_REF_NAME, '^v?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$')

    if (-not $tagMatch.Success) {
      throw "Git tag '$($env:GITHUB_REF_NAME)' must match vMAJOR.MINOR.PATCH or vMAJOR.MINOR.PATCH+BUILD for MSIX packaging."
    }

    $buildNumber = if ($tagMatch.Groups[4].Success) {
      [int]$tagMatch.Groups[4].Value
    } else {
      [int]$PubspecVersion.BuildNumber
    }

    return "$($tagMatch.Groups[1].Value).$($tagMatch.Groups[2].Value).$($tagMatch.Groups[3].Value).$buildNumber"
  }

  return $PubspecVersion.MsixVersion
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pubspecPath = Join-Path $repoRoot "pubspec.yaml"
$pubspecVersion = Get-PubspecVersionInfo -Path $pubspecPath
$msixVersion = Get-MsixVersion -PubspecVersion $pubspecVersion
$outputPath = Join-Path $repoRoot "build/windows/x64/runner/Release"
$outputName = "chibot-windows-x64"

Write-Host "Creating MSIX package version $msixVersion"

Push-Location $repoRoot
try {
  dart run msix:create `
    --architecture x64 `
    --build-windows false `
    --install-certificate false `
    --output-name $outputName `
    --output-path $outputPath `
    --version $msixVersion
}
finally {
  Pop-Location
}
