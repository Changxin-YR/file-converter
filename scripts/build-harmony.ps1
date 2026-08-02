# build-harmony.ps1
# Builds the FormatConverter HarmonyOS project using the project's Hvigor entry.
# Locates the output HAP and reports its path and size.
# Exits with non-zero code on failure.

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

# Locate hvigor wrapper. Prefer the project-local wrapper; fall back to DevEco Studio's bundled hvigor.
$hvigor = $null
$localCandidates = @(
  (Join-Path $projectRoot 'hvigorw.bat'),
  (Join-Path $projectRoot 'hvigorw')
)
foreach ($candidate in $localCandidates) {
  if (Test-Path $candidate) {
    $hvigor = $candidate
    break
  }
}

if (-not $hvigor) {
  # DevEco Studio install locations
  $devecoCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'),
    (Join-Path $env:LOCALAPPDATA 'Huawei\DevEco Studio\bin\hvigorw.bat'),
    (Join-Path ${env:ProgramFiles(x86)} 'Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'),
    (Join-Path ${env:ProgramFiles(x86)} 'Huawei\DevEco Studio\bin\hvigorw.bat'),
    (Join-Path $env:ProgramFiles 'Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'),
    (Join-Path $env:ProgramFiles 'Huawei\DevEco Studio\bin\hvigorw.bat')
  )
  foreach ($candidate in $devecoCandidates) {
    if ($candidate -and (Test-Path $candidate)) {
      $hvigor = $candidate
      break
    }
  }
}

if (-not $hvigor) {
  Write-Output "BUILD: BLOCKED - hvigor wrapper not found in project root or DevEco Studio."
  Write-Output "Expected at: $(Join-Path $projectRoot 'hvigorw.bat') or inside DevEco Studio install."
  Write-Output "Install the API 22 (6.0.2) SDK in DevEco Studio first, then retry."
  exit 1
}

Write-Output "Using hvigor: $hvigor"
Write-Output "Starting HarmonyOS build (assembleHap)..."
$buildStart = Get-Date

Push-Location $projectRoot
try {
  & $hvigor assembleHap --no-daemon
  $exitCode = $LASTEXITCODE
} finally {
  Pop-Location
}

if ($exitCode -ne 0) {
  Write-Output "BUILD: FAILED (exit code $exitCode)"
  exit $exitCode
}

$buildEnd = Get-Date
$elapsed = ($buildEnd - $buildStart).TotalSeconds

# Locate the HAP artifact
$hap = Get-ChildItem -Path (Join-Path $projectRoot 'entry\build\default\outputs\default') -Filter '*.hap' -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if ($hap) {
  $sizeKB = [math]::Round($hap.Length / 1KB, 1)
  Write-Output "BUILD: SUCCESS in $([math]::Round($elapsed,1))s"
  Write-Output "ARTIFACT: $($hap.FullName)"
  Write-Output "SIZE: $sizeKB KB"
  exit 0
} else {
  Write-Output "BUILD: SUCCESS but HAP artifact not found under entry\build\default\outputs\default."
  exit 1
}
