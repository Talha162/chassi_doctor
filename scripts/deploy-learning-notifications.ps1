param(
  [string]$FirebaseProjectId = "chassis-doctor",
  [string]$WebhookSecret
)

$ErrorActionPreference = "Stop"

function Get-DotEnvValue {
  param(
    [string]$Path,
    [string]$Name
  )

  $line = Get-Content $Path | Where-Object { $_ -match "^\s*$Name\s*=" } | Select-Object -First 1
  if (-not $line) {
    return $null
  }

  $value = $line -replace "^\s*$Name\s*=\s*", ""
  $value = $value.Trim()

  if (
    ($value.StartsWith('"') -and $value.EndsWith('"')) -or
    ($value.StartsWith("'") -and $value.EndsWith("'"))
  ) {
    $value = $value.Substring(1, $value.Length - 2)
  }

  return $value
}

$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root ".env"

if (-not (Test-Path $envPath)) {
  throw ".env file not found at $envPath"
}

$supabaseUrl = Get-DotEnvValue -Path $envPath -Name "SUPABASE_URL"
$serviceRoleKey = Get-DotEnvValue -Path $envPath -Name "SUPABASE_SERVICE_ROLE_KEY"

if (-not $supabaseUrl) {
  throw "SUPABASE_URL is missing in .env"
}

if (-not $serviceRoleKey) {
  throw "SUPABASE_SERVICE_ROLE_KEY is missing in .env"
}

if (-not $WebhookSecret) {
  $WebhookSecret = [guid]::NewGuid().ToString("N")
}

Write-Host "Setting Firebase project to $FirebaseProjectId"
cmd /c firebase.cmd use $FirebaseProjectId

Write-Host "Installing function dependencies"
Push-Location (Join-Path $root "functions")
try {
  cmd /c npm.cmd install
  cmd /c node --check index.js
} finally {
  Pop-Location
}

Write-Host "Setting Firebase function secrets"
$supabaseUrl | cmd /c firebase.cmd functions:secrets:set SUPABASE_URL
$serviceRoleKey | cmd /c firebase.cmd functions:secrets:set SUPABASE_SERVICE_ROLE_KEY
$WebhookSecret | cmd /c firebase.cmd functions:secrets:set SUPABASE_WEBHOOK_SECRET

Write-Host "Deploying Cloud Function"
cmd /c firebase.cmd deploy --only functions:handleLearningNotificationEvent

Write-Host ""
Write-Host "Use this webhook secret in Supabase:"
Write-Host $WebhookSecret
Write-Host ""
Write-Host "After deployment, copy the HTTPS function URL from Firebase output"
Write-Host "and replace the placeholders in supabase/migrations/003_learning_notification_webhook.sql"
