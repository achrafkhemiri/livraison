param(
    [string]$Container = "smart-delivery-mysql",
    [string]$User = "app_user",
    [string]$Password = "app123",
    [string]$Database = "livrasion_db",
    [string]$OutputFile = "./livrasion_db_backup_$(Get-Date -Format yyyyMMdd_HHmmss).sql"
)

$command = "mysqldump --no-tablespaces -u$User -p$Password --databases $Database"
docker exec $Container sh -c $command | Out-File -Encoding ascii $OutputFile
Write-Host "Backup created: $OutputFile"
