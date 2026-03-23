param(
    [string]$Container = "smart-delivery-mysql",
    [string]$User = "app_user",
    [string]$Password = "app123",
    [string]$Database = "livrasion_db",
    [string]$InputFile = "./livrasion_db_backup_utf8.sql"
)

if (-not (Test-Path $InputFile)) {
    Write-Error "SQL file not found: $InputFile"
    exit 1
}

# Remove CREATE DATABASE and USE statements so app_user can import safely.
$sql = Get-Content -Raw $InputFile
$sanitized = ($sql -split "`r?`n") |
    Where-Object { $_ -notmatch '^CREATE DATABASE' -and $_ -notmatch '^USE\s+`' } |
    Out-String

$sanitized | docker exec -i $Container mysql -u$User -p$Password $Database
Write-Host "Restore completed into '$Database' from: $InputFile"
