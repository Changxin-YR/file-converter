# check-standard.ps1
# Local static gate for the FormatConverter HarmonyOS project.
# Exits with non-zero code on failure.

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

$failed = 0
$warned = 0

function Write-Pass([string]$msg) { Write-Output "[PASS] $msg" }
function Write-Fail([string]$msg) { Write-Output "[FAIL] $msg" }
function Write-Warn([string]$msg) { Write-Output "[WARN] $msg" }

# 1. Required standard docs (non-empty files)
$requiredDocs = @(
  'README.md',
  'AGENTS.md',
  'tasks.md',
  'changes.md',
  'design.md',
  'design-qa.md',
  'docs/qa/README.md'
)

foreach ($doc in $requiredDocs) {
  $path = Join-Path $projectRoot $doc
  if ((Test-Path $path) -and ((Get-Item $path).Length -gt 0)) {
    Write-Pass "Standard doc exists: $doc"
  } else {
    Write-Fail "Missing standard doc: $doc"
    $failed++
  }
}

# 2. Stage-model key files
$stageFiles = @(
  'build-profile.json5',
  'oh-package.json5',
  'hvigorfile.ts',
  'entry/build-profile.json5',
  'entry/oh-package.json5',
  'entry/hvigorfile.ts',
  'entry/src/main/module.json5',
  'entry/src/main/resources/base/profile/main_pages.json'
)

foreach ($file in $stageFiles) {
  $path = Join-Path $projectRoot $file
  if ((Test-Path $path) -and ((Get-Item $path).Length -gt 0)) {
    Write-Pass "Stage file exists: $file"
  } else {
    Write-Fail "Missing Stage file: $file"
    $failed++
  }
}

# 3. module.json5 key declarations
$modulePath = Join-Path $projectRoot 'entry/src/main/module.json5'
if (Test-Path $modulePath) {
  $moduleText = Get-Content $modulePath -Raw
  if ($moduleText -match '"type":\s*"entry"') {
    Write-Pass 'module.json5 declares entry module type'
  } else {
    Write-Fail 'module.json5 missing entry module type'
    $failed++
  }
  if ($moduleText -match '"mainElement"') {
    Write-Pass 'module.json5 declares mainAbility'
  } else {
    Write-Fail 'module.json5 missing mainElement'
    $failed++
  }
  if ($moduleText -match '"pages"') {
    Write-Pass 'module.json5 declares pages profile'
  } else {
    Write-Fail 'module.json5 missing pages profile'
    $failed++
  }

  foreach ($device in @('"phone"', '"tablet"', '"2in1"')) {
    if ($moduleText -match [regex]::Escape($device)) {
      Write-Pass "module.json5 declares device: $device"
    } else {
      Write-Warn "module.json5 missing device type: $device"
      $warned++
    }
  }
}

# 4. ArkTS source and resources directories
foreach ($dir in @('entry/src/main/ets', 'entry/src/main/resources')) {
  $path = Join-Path $projectRoot $dir
  if (Test-Path $path) {
    Write-Pass "Directory exists: $dir"
  } else {
    Write-Fail "Missing directory: $dir"
    $failed++
  }
}

foreach ($dir in @('pages', 'components', 'services', 'common')) {
  $path = Join-Path $projectRoot ("entry/src/main/ets/" + $dir)
  if (-not (Test-Path $path)) {
    Write-Warn "Source responsibility directory not yet created: entry/src/main/ets/$dir (documented as design target)"
    $warned++
  }
}

# 5. main_pages.json entries
$pagesPath = Join-Path $projectRoot 'entry/src/main/resources/base/profile/main_pages.json'
if ((Test-Path $pagesPath) -and ((Get-Content $pagesPath -Raw) -match '"src"' -and (Get-Content $pagesPath -Raw) -match 'pages/')) {
  Write-Pass 'main_pages.json configured page entries'
} else {
  Write-Fail 'main_pages.json missing pages/ entry'
  $failed++
}

# 6. tasks.md status words
$tasksPath = Join-Path $projectRoot 'tasks.md'
if (Test-Path $tasksPath) {
  $tasksText = Get-Content $tasksPath -Raw
  foreach ($status in @('pending', 'in_progress', 'done', 'blocked')) {
    if ($tasksText -match $status) {
      Write-Pass "tasks.md defines status: $status"
    } else {
      Write-Fail "tasks.md missing status: $status"
      $failed++
    }
  }
}

# 7. design-qa.md has traceable status
$qaPath = Join-Path $projectRoot 'design-qa.md'
if (Test-Path $qaPath) {
  $qaText = Get-Content $qaPath -Raw
  if ($qaText -match 'passed' -or $qaText -match 'blocked') {
    Write-Pass 'design-qa.md contains traceable QA status'
  } else {
    Write-Fail 'design-qa.md missing passed/blocked QA status'
    $failed++
  }
}

# 8. API version alignment (API 22 / 6.0.2)
$appJsonPath = Join-Path $projectRoot 'AppScope/app.json5'
if (Test-Path $appJsonPath) {
  $appJson = Get-Content $appJsonPath -Raw
  if ($appJson -match '"targetAPIVersion":\s*22' -and $appJson -match '"minAPIVersion":\s*22') {
    Write-Pass 'app.json5 targets API 22'
  } else {
    Write-Fail 'app.json5 does not target API 22'
    $failed++
  }
}

$buildProfilePath = Join-Path $projectRoot 'build-profile.json5'
if (Test-Path $buildProfilePath) {
  $buildProfile = Get-Content $buildProfilePath -Raw
  if ($buildProfile -match '6\.0\.2\(22\)') {
    Write-Pass 'build-profile.json5 compatibleSdkVersion is 6.0.2(22)'
  } else {
    Write-Warn 'build-profile.json5 compatibleSdkVersion is not 6.0.2(22)'
    $warned++
  }
}

Write-Output ""
if ($failed -gt 0) {
  Write-Output "RESULT: FAILED ($failed failure(s), $warned warning(s))"
  exit 1
} else {
  Write-Output "RESULT: PASSED ($warned warning(s))"
  exit 0
}
