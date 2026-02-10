# =============================================================================
# 🚀 Script de configuration OSRM pour la Tunisie
# =============================================================================
# Ce script configure automatiquement OSRM avec les données routières de Tunisie
# =============================================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "🚀 Configuration OSRM - Tunisie" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$osrmDataPath = "C:\Users\USER\Desktop\Nouveau dossier (2)\osrm-data"
$dockerVolume = "C:/Users/USER/Desktop/Nouveau dossier (2)/osrm-data:/data"

# Vérifier Docker
Write-Host "🔍 Vérification de Docker..." -ForegroundColor Yellow
$dockerRunning = docker info 2>$null
if (-not $?) {
    Write-Host "❌ Docker n'est pas en cours d'exécution!" -ForegroundColor Red
    Write-Host "   Veuillez démarrer Docker Desktop et relancer ce script."
    exit 1
}
Write-Host "✅ Docker est opérationnel" -ForegroundColor Green
Write-Host ""

# Aller dans le dossier
Set-Location $osrmDataPath

# Vérifier si les données existent
if (-not (Test-Path "tunisia-latest.osm.pbf")) {
    Write-Host "📥 Téléchargement des données OSM de Tunisie..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://download.geofabrik.de/africa/tunisia-latest.osm.pbf" -OutFile "tunisia-latest.osm.pbf"
    Write-Host "✅ Téléchargement terminé" -ForegroundColor Green
} else {
    Write-Host "✅ Données OSM déjà présentes" -ForegroundColor Green
}
Write-Host ""

# Étape 1: Extraction
if (-not (Test-Path "tunisia-latest.osrm")) {
    Write-Host "📦 Étape 1/3: Extraction des données routières..." -ForegroundColor Yellow
    Write-Host "   (Cette étape peut prendre 5-10 minutes)" -ForegroundColor Gray
    docker run -t -v $dockerVolume osrm/osrm-backend osrm-extract -p /opt/car.lua /data/tunisia-latest.osm.pbf
    Write-Host "✅ Extraction terminée" -ForegroundColor Green
} else {
    Write-Host "✅ Extraction déjà effectuée" -ForegroundColor Green
}
Write-Host ""

# Étape 2: Partition
if (-not (Test-Path "tunisia-latest.osrm.partition")) {
    Write-Host "📦 Étape 2/3: Partitionnement..." -ForegroundColor Yellow
    docker run -t -v $dockerVolume osrm/osrm-backend osrm-partition /data/tunisia-latest.osrm
    Write-Host "✅ Partitionnement terminé" -ForegroundColor Green
} else {
    Write-Host "✅ Partitionnement déjà effectué" -ForegroundColor Green
}
Write-Host ""

# Étape 3: Customisation
if (-not (Test-Path "tunisia-latest.osrm.cell_metrics")) {
    Write-Host "📦 Étape 3/3: Customisation..." -ForegroundColor Yellow
    docker run -t -v $dockerVolume osrm/osrm-backend osrm-customize /data/tunisia-latest.osrm
    Write-Host "✅ Customisation terminée" -ForegroundColor Green
} else {
    Write-Host "✅ Customisation déjà effectuée" -ForegroundColor Green
}
Write-Host ""

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "🎉 Configuration OSRM terminée!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Pour lancer le serveur OSRM, exécutez:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   docker run -d -p 5000:5000 -v `"$dockerVolume`" --name osrm-tunisia osrm/osrm-backend osrm-routed --algorithm mld /data/tunisia-latest.osrm" -ForegroundColor White
Write-Host ""
Write-Host "📍 Le serveur sera accessible sur: http://localhost:5000" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 Pour tester:" -ForegroundColor Yellow
Write-Host "   Invoke-WebRequest 'http://localhost:5000/route/v1/driving/10.6,34.95;10.61,34.96'" -ForegroundColor White
