// =============================================================================
// CONFIGURATION
// =============================================================================

const OSRM_URL = 'http://localhost:5000';
let osrmConnected = false;

// =============================================================================
// DATA & STATE
// =============================================================================

let allClients = [{"order_id":"ORDSF001","lat":34.7421,"lon":10.7548},{"order_id":"ORDSF002","lat":34.7354,"lon":10.7689},{"order_id":"ORDSF003","lat":34.7482,"lon":10.7715},{"order_id":"ORDSF004","lat":34.7398,"lon":10.7462},{"order_id":"ORDSF005","lat":34.7516,"lon":10.7581},{"order_id":"ORDSF006","lat":34.7299,"lon":10.7637},{"order_id":"ORDSF007","lat":34.7335,"lon":10.7524},{"order_id":"ORDSF008","lat":34.7468,"lon":10.7812},{"order_id":"ORDSF009","lat":34.7562,"lon":10.7696},{"order_id":"ORDSF010","lat":34.7214,"lon":10.7609},{"order_id":"ORDSF011","lat":34.7278,"lon":10.7451},{"order_id":"ORDSF012","lat":34.7643,"lon":10.7557},{"order_id":"ORDSF013","lat":34.7386,"lon":10.7864},{"order_id":"ORDSF014","lat":34.7539,"lon":10.7428},{"order_id":"ORDSF015","lat":34.7321,"lon":10.7789},{"order_id":"ORDSF016","lat":34.7475,"lon":10.7356},{"order_id":"ORDSF017","lat":34.7618,"lon":10.7702},{"order_id":"ORDSF018","lat":34.7243,"lon":10.7529},{"order_id":"ORDSF019","lat":34.7584,"lon":10.7831},{"order_id":"ORDSF020","lat":34.7367,"lon":10.7398}];
let selectedClients = new Set();
let map, depotMarker, clientMarkers = [], routeLines = [];
let settingDepot = false;
let addingClient = false;
let distanceCache = {};

// =============================================================================
// INITIALIZATION
// =============================================================================

document.addEventListener('DOMContentLoaded', function() {
    initMap();
    renderClientList();
    updateDepotMarker();
    checkOSRMConnection();
});

function initMap() {
    map = L.map('map').setView([34.74, 10.76], 11);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap | OSRM Local Routing 🇹🇳'
    }).addTo(map);

    // Click handler for setting depot or adding client
    map.on('click', function(e) {
        if (settingDepot) {
            document.getElementById('depot-lat').value = e.latlng.lat.toFixed(6);
            document.getElementById('depot-lon').value = e.latlng.lng.toFixed(6);
            updateDepotMarker();
            settingDepot = false;
            showToast('Position du livreur mise à jour', 'success');
        } else if (addingClient) {
            document.getElementById('new-client-lat').value = e.latlng.lat.toFixed(6);
            document.getElementById('new-client-lon').value = e.latlng.lng.toFixed(6);
            addingClient = false;
            showToast('Position sélectionnée - Entrez l\'ID et cliquez sur Ajouter', 'success');
        }
    });
}

async function checkOSRMConnection() {
    const statusDot = document.getElementById('osrm-status-dot');
    const statusText = document.getElementById('osrm-status-text');

    try {
        const response = await fetch(`${OSRM_URL}/route/v1/driving/10.6,34.95;10.61,34.96`);
        const data = await response.json();

        if (data.code === 'Ok') {
            osrmConnected = true;
            statusDot.classList.add('connected');
            statusText.textContent = 'OSRM Connecté ✓';
            showToast('🚀 OSRM local connecté - Routes réelles!', 'success');
        } else {
            throw new Error('Invalid response');
        }
    } catch (error) {
        osrmConnected = false;
        statusDot.classList.remove('connected');
        statusText.textContent = 'OSRM non disponible';
        showToast('⚠️ OSRM non connecté - Mode Haversine', 'error');
    }
}

// =============================================================================
// DEPOT (DRIVER) FUNCTIONS
// =============================================================================

function updateDepotMarker() {
    const lat = parseFloat(document.getElementById('depot-lat').value);
    const lon = parseFloat(document.getElementById('depot-lon').value);

    if (depotMarker) {
        map.removeLayer(depotMarker);
    }

    const depotIcon = L.divIcon({
        html: '<div class="depot-marker">🚚</div>',
        className: '',
        iconSize: [50, 50],
        iconAnchor: [25, 25]
    });

    depotMarker = L.marker([lat, lon], { icon: depotIcon })
        .addTo(map)
        .bindPopup(`
            <div style="font-family: Poppins; min-width: 150px;">
                <h4 style="color: #2196f3; margin: 0 0 10px 0;">🚚 Livreur</h4>
                <p><b>Lat:</b> ${lat.toFixed(6)}</p>
                <p><b>Lon:</b> ${lon.toFixed(6)}</p>
            </div>
        `);

    distanceCache = {}; // Clear cache when depot changes
}

function setDepotOnMap() {
    settingDepot = true;
    addingClient = false;
    showToast('Cliquez sur la carte pour définir la position du livreur');
}

function centerOnDepot() {
    const lat = parseFloat(document.getElementById('depot-lat').value);
    const lon = parseFloat(document.getElementById('depot-lon').value);
    map.setView([lat, lon], 14);
}

// =============================================================================
// CLIENT FUNCTIONS
// =============================================================================

function renderClientList(filter = '') {
    const container = document.getElementById('client-list');
    container.innerHTML = '';

    allClients.forEach((client, index) => {
        if (filter && !client.order_id.toLowerCase().includes(filter.toLowerCase())) {
            return;
        }

        const isSelected = selectedClients.has(index);
        const div = document.createElement('div');
        div.className = 'client-item' + (isSelected ? ' selected' : '');
        div.innerHTML = `
            <input type="checkbox" ${isSelected ? 'checked' : ''} onchange="toggleClient(${index})">
            <div class="client-info">
                <div class="client-id">${client.order_id}</div>
                <div class="client-coords">${client.lat.toFixed(4)}, ${client.lon.toFixed(4)}</div>
            </div>
        `;
        div.onclick = (e) => {
            if (e.target.type !== 'checkbox') {
                toggleClient(index);
            }
        };
        container.appendChild(div);
    });

    updateSelectedCount();
    updateClientMarkers();
}

function toggleClient(index) {
    if (selectedClients.has(index)) {
        selectedClients.delete(index);
    } else {
        selectedClients.add(index);
    }
    renderClientList(document.getElementById('client-search').value);
}

function selectAllClients() {
    allClients.forEach((_, index) => selectedClients.add(index));
    renderClientList(document.getElementById('client-search').value);
    showToast('Tous les clients sélectionnés', 'success');
}

function deselectAllClients() {
    selectedClients.clear();
    renderClientList(document.getElementById('client-search').value);
    clearRoute();
    showToast('Sélection effacée');
}

function filterClients() {
    renderClientList(document.getElementById('client-search').value);
}

function updateSelectedCount() {
    document.getElementById('selected-count').textContent = selectedClients.size;
}

function updateClientMarkers() {
    clientMarkers.forEach(m => map.removeLayer(m));
    clientMarkers = [];

    selectedClients.forEach(index => {
        const client = allClients[index];
        const icon = L.divIcon({
            html: `<div class="client-marker">${index + 1}</div>`,
            className: '',
            iconSize: [35, 35],
            iconAnchor: [17, 17]
        });

        const marker = L.marker([client.lat, client.lon], { icon })
            .addTo(map)
            .bindPopup(`
                <div style="font-family: Poppins; min-width: 150px;">
                    <h4 style="color: #f44336; margin: 0 0 10px 0;">📦 Client</h4>
                    <p><b>Commande:</b> ${client.order_id}</p>
                    <p><b>Lat:</b> ${client.lat.toFixed(6)}</p>
                    <p><b>Lon:</b> ${client.lon.toFixed(6)}</p>
                </div>
            `);
        clientMarkers.push(marker);
    });
}

function addNewClient() {
    const id = document.getElementById('new-client-id').value.trim();
    const lat = parseFloat(document.getElementById('new-client-lat').value);
    const lon = parseFloat(document.getElementById('new-client-lon').value);

    if (!id || isNaN(lat) || isNaN(lon)) {
        showToast('Veuillez remplir tous les champs', 'error');
        return;
    }

    allClients.push({ order_id: id, lat: lat, lon: lon });
    const newIndex = allClients.length - 1;
    selectedClients.add(newIndex);

    // Clear form
    document.getElementById('new-client-id').value = '';
    document.getElementById('new-client-lat').value = '';
    document.getElementById('new-client-lon').value = '';

    renderClientList();
    showToast('Client ajouté: ' + id, 'success');
}

function addClientOnMap() {
    addingClient = true;
    settingDepot = false;
    showToast('Cliquez sur la carte pour sélectionner la position du client');
}

// =============================================================================
// OSRM ROUTING
// =============================================================================

async function getOSRMDistance(lat1, lon1, lat2, lon2) {
    const cacheKey = `${lat1},${lon1}-${lat2},${lon2}`;
    if (distanceCache[cacheKey]) {
        return distanceCache[cacheKey];
    }

    if (osrmConnected) {
        try {
            const url = `${OSRM_URL}/route/v1/driving/${lon1},${lat1};${lon2},${lat2}?overview=false`;
            const response = await fetch(url);
            const data = await response.json();

            if (data.code === 'Ok' && data.routes.length > 0) {
                const result = {
                    distance: data.routes[0].distance / 1000,
                    duration: data.routes[0].duration / 60
                };
                distanceCache[cacheKey] = result;
                return result;
            }
        } catch (error) {
            console.error('OSRM error:', error);
        }
    }

    // Fallback to Haversine
    const dist = haversineDistance(lat1, lon1, lat2, lon2) * 1.3;
    return { distance: dist, duration: dist * 2 };
}

async function getOSRMRoute(points) {
    if (!osrmConnected) return null;

    const coords = points.map(p => `${p[1]},${p[0]}`).join(';');
    const url = `${OSRM_URL}/route/v1/driving/${coords}?overview=full&geometries=polyline`;

    try {
        const response = await fetch(url);
        const data = await response.json();

        if (data.code === 'Ok' && data.routes.length > 0) {
            return {
                geometry: data.routes[0].geometry,
                distance: data.routes[0].distance / 1000,
                duration: data.routes[0].duration / 60
            };
        }
    } catch (error) {
        console.error('OSRM route error:', error);
    }
    return null;
}

function decodePolyline(encoded) {
    const points = [];
    let index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
        let b, shift = 0, result = 0;

        do {
            b = encoded.charCodeAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);

        const dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;

        do {
            b = encoded.charCodeAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);

        const dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        points.push([lat / 1e5, lng / 1e5]);
    }

    return points;
}

function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}

// =============================================================================
// TSP OPTIMIZATION
// =============================================================================

async function calculateOptimalRoute() {
    if (selectedClients.size === 0) {
        showToast('Sélectionnez au moins un client', 'error');
        return;
    }

    const loading = document.getElementById('loading');
    const loadingText = document.getElementById('loading-text');
    const loadingSubtext = document.getElementById('loading-subtext');
    const progressFill = document.getElementById('progress-fill');
    const progressText = document.getElementById('progress-text');

    loading.classList.add('active');
    try {
        // Get depot and clients
        const depotLat = parseFloat(document.getElementById('depot-lat').value);
        const depotLon = parseFloat(document.getElementById('depot-lon').value);
        const clients = Array.from(selectedClients).map(i => allClients[i]);
        const n = clients.length + 1;

        loadingText.textContent = 'Calcul de la matrice des distances...';
        loadingSubtext.textContent = osrmConnected ? 'Via OSRM (routes réelles)' : 'Via Haversine (estimation)';

        // Build distance matrix
        const points = [[depotLat, depotLon], ...clients.map(c => [c.lat, c.lon])];
        const distMatrix = [];
        const timeMatrix = [];

        let progress = 0;
        const totalCalls = n * n;

        for (let i = 0; i < n; i++) {
            distMatrix[i] = [];
            timeMatrix[i] = [];
            for (let j = 0; j < n; j++) {
                if (i === j) {
                    distMatrix[i][j] = 0;
                    timeMatrix[i][j] = 0;
                } else {
                    const result = await getOSRMDistance(
                        points[i][0], points[i][1],
                        points[j][0], points[j][1]
                    );
                    distMatrix[i][j] = result.distance;
                    timeMatrix[i][j] = result.duration;
                }
                progress++;
                const pct = Math.round((progress / totalCalls) * 60);
                progressFill.style.width = pct + '%';
                progressText.textContent = `Matrice: ${progress}/${totalCalls}`;
            }
        }

        loadingText.textContent = 'Optimisation Open TSP...';
        loadingSubtext.textContent = 'Recherche du plus court chemin global';
        progressFill.style.width = '70%';

        // Solve Open TSP (sans retour obligatoire au dépôt)
        // On cherche le chemin le plus court qui part du dépôt et visite tous les clients
        const route = solveOpenTSP(distMatrix, timeMatrix);
        progressFill.style.width = '90%';

        // Calculate totals
        let totalDist = 0;
        let totalTime = 0;
        for (let i = 0; i < route.length - 1; i++) {
            totalDist += distMatrix[route[i]][route[i + 1]];
            totalTime += timeMatrix[route[i]][route[i + 1]];
        }

        loadingText.textContent = 'Génération de la route...';

        // Get ordered points (chemin optimal)
        const orderedPoints = route.map(i => points[i]);

        // Draw route
        await drawRealRoute(orderedPoints, route, clients);

        progressFill.style.width = '100%';

        // Display results
        const orderedClients = route.slice(1).map(i => clients[i - 1]);
        displayResults(totalDist, totalTime, orderedClients);

        showToast('✅ Trajet optimal calculé!', 'success');
    } catch (error) {
        console.error(error);
        showToast(`Erreur: ${error?.message || error}`, 'error');
    } finally {
        loading.classList.remove('active');
    }
}

function createRouteLine(coords, options) {
    const antPathFn = L?.polyline?.antPath;
    if (typeof antPathFn === 'function') {
        return antPathFn(coords, options);
    }

    if (!createRouteLine._warned) {
        createRouteLine._warned = true;
        console.warn('leaflet-ant-path not available; falling back to regular polyline');
        showToast('leaflet-ant-path non chargé: polyline simple', 'error');
    }

    const { color, weight, opacity, dashArray } = options || {};
    return L.polyline(coords, {
        color: color || '#1B998B',
        weight: weight || 5,
        opacity: opacity ?? 0.8,
        dashArray: dashArray || undefined
    });
}

function nearestNeighborTSP(distMatrix) {
    const n = distMatrix.length;
    const visited = new Set([0]);
    const route = [0];

    while (route.length < n) {
        const last = route[route.length - 1];
        let nearest = -1;
        let minDist = Infinity;

        for (let i = 0; i < n; i++) {
            if (!visited.has(i) && distMatrix[last][i] < minDist) {
                minDist = distMatrix[last][i];
                nearest = i;
            }
        }

        route.push(nearest);
        visited.add(nearest);
    }

    return route;
}

// =============================================================================
// OPEN TSP - Plus court chemin SANS retour obligatoire
// =============================================================================

function solveOpenTSP(distMatrix, timeMatrix) {
    const n = distMatrix.length;

    if (n <= 2) {
        // Cas simple: dépôt + 0 ou 1 client
        return Array.from({length: n}, (_, i) => i);
    }

    // Pour l'Open TSP, on teste plusieurs stratégies et on garde la meilleure
    let bestRoute = null;
    let bestDistance = Infinity;

    // =========================================================================
    // STRATÉGIE 1: Nearest Neighbor classique + 2-opt
    // =========================================================================
    const nnRoute = nearestNeighborTSP(distMatrix);
    const nnOptRoute = openTwoOptImprovement([...nnRoute], distMatrix);
    const nnOptDist = calculateOpenRouteDistance(nnOptRoute, distMatrix);
    if (nnOptDist < bestDistance) {
        bestDistance = nnOptDist;
        bestRoute = [...nnOptRoute];
    }

    // =========================================================================
    // STRATÉGIE 2: Tester les K meilleurs candidats comme destination finale
    // Pour Open TSP, la destination finale a un impact majeur sur la distance
    // =========================================================================
    const candidateEnds = findBestEndCandidates(distMatrix, Math.min(n - 1, 15));
    for (const endClient of candidateEnds) {
        const route = buildRouteEndingAt(distMatrix, endClient);
        const optRoute = openTwoOptImprovement([...route], distMatrix);
        const dist = calculateOpenRouteDistance(optRoute, distMatrix);
        if (dist < bestDistance) {
            bestDistance = dist;
            bestRoute = [...optRoute];
        }
    }

    // =========================================================================
    // STRATÉGIE 3: Insertion la moins coûteuse (greedy insertion) + 2-opt
    // =========================================================================
    const insertionRoute = greedyInsertionOpenTSP(distMatrix);
    const insertionOptRoute = openTwoOptImprovement([...insertionRoute], distMatrix);
    const insertionDist = calculateOpenRouteDistance(insertionOptRoute, distMatrix);
    if (insertionDist < bestDistance) {
        bestDistance = insertionDist;
        bestRoute = [...insertionOptRoute];
    }

    // =========================================================================
    // STRATÉGIE 4: Savings Algorithm adapté pour Open TSP
    // =========================================================================
    const savingsRoute = savingsAlgorithmOpenTSP(distMatrix);
    const savingsOptRoute = openTwoOptImprovement([...savingsRoute], distMatrix);
    const savingsDist = calculateOpenRouteDistance(savingsOptRoute, distMatrix);
    if (savingsDist < bestDistance) {
        bestDistance = savingsDist;
        bestRoute = [...savingsOptRoute];
    }

    // =========================================================================
    // STRATÉGIE 5: Or-opt amélioration sur le meilleur résultat
    // =========================================================================
    const orOptRoute = orOptImprovement([...bestRoute], distMatrix);
    const orOptDist = calculateOpenRouteDistance(orOptRoute, distMatrix);
    if (orOptDist < bestDistance) {
        bestDistance = orOptDist;
        bestRoute = [...orOptRoute];
    }

    // =========================================================================
    // STRATÉGIE 6: 3-opt limité pour améliorer encore
    // =========================================================================
    if (n <= 30) {
        const threeOptRoute = threeOptImprovement([...bestRoute], distMatrix);
        const threeOptDist = calculateOpenRouteDistance(threeOptRoute, distMatrix);
        if (threeOptDist < bestDistance) {
            bestDistance = threeOptDist;
            bestRoute = [...threeOptRoute];
        }
    }

    console.log(`Open TSP (${n-1} clients): Meilleure distance = ${bestDistance.toFixed(2)} km`);
    return bestRoute;
}

function calculateOpenRouteDistance(route, distMatrix) {
    let total = 0;
    for (let i = 0; i < route.length - 1; i++) {
        total += distMatrix[route[i]][route[i + 1]];
    }
    return total;
}

// Trouver les K meilleurs candidats pour être la destination finale
function findBestEndCandidates(distMatrix, k) {
    const n = distMatrix.length;
    const candidates = [];

    for (let i = 1; i < n; i++) {
        // Score basé sur: éloignement du dépôt + proximité moyenne des autres clients
        const distFromDepot = distMatrix[0][i];
        let avgDistToOthers = 0;
        for (let j = 1; j < n; j++) {
            if (i !== j) avgDistToOthers += distMatrix[i][j];
        }
        avgDistToOthers /= (n - 2) || 1;

        // Les bons candidats finaux sont éloignés du dépôt mais proches des autres
        const score = distFromDepot - avgDistToOthers * 0.5;
        candidates.push({ node: i, score });
    }

    // Trier par score décroissant et prendre les K premiers
    candidates.sort((a, b) => b.score - a.score);
    return candidates.slice(0, k).map(c => c.node);
}

function buildRouteEndingAt(distMatrix, endNode) {
    const n = distMatrix.length;
    const route = [0];
    const visited = new Set([0, endNode]);

    // Construire le chemin en évitant endNode jusqu'à la fin
    while (route.length < n - 1) {
        const last = route[route.length - 1];
        let nearest = -1;
        let minDist = Infinity;

        for (let i = 1; i < n; i++) {
            if (!visited.has(i) && distMatrix[last][i] < minDist) {
                minDist = distMatrix[last][i];
                nearest = i;
            }
        }

        if (nearest === -1) break;
        route.push(nearest);
        visited.add(nearest);
    }

    // Ajouter le nœud final
    route.push(endNode);
    return route;
}

// Savings Algorithm adapté pour Open TSP
function savingsAlgorithmOpenTSP(distMatrix) {
    const n = distMatrix.length;
    if (n <= 2) return Array.from({length: n}, (_, i) => i);

    // Calculer les savings pour chaque paire de clients
    const savings = [];
    for (let i = 1; i < n; i++) {
        for (let j = i + 1; j < n; j++) {
            // Saving = coût d'aller du dépôt à i + dépôt à j - coût de i à j
            const save = distMatrix[0][i] + distMatrix[0][j] - distMatrix[i][j];
            savings.push({ i, j, save });
        }
    }

    // Trier par savings décroissant
    savings.sort((a, b) => b.save - a.save);

    // Construire la route en fusionnant
    const routes = {};
    const routeEnds = {};

    for (let i = 1; i < n; i++) {
        routes[i] = [i];
        routeEnds[i] = { start: i, end: i };
    }

    for (const { i, j } of savings) {
        const routeI = routes[routeEnds[i]?.start];
        const routeJ = routes[routeEnds[j]?.start];

        if (!routeI || !routeJ || routeI === routeJ) continue;

        // Fusionner si possible (i est à une extrémité et j à une extrémité)
        const iIsEnd = routeEnds[i]?.end === i;
        const jIsStart = routeEnds[j]?.start === j;

        if (iIsEnd && jIsStart && routeI !== routeJ) {
            // Fusionner routeI + routeJ
            const newRoute = [...routeI, ...routeJ];
            const startNode = routeI[0];
            const endNode = routeJ[routeJ.length - 1];

            routes[startNode] = newRoute;
            delete routes[routeEnds[j].start];

            routeEnds[startNode] = { start: startNode, end: endNode };
            routeEnds[endNode] = { start: startNode, end: endNode };
        }
    }

    // Trouver la plus longue route construite
    let longestRoute = [];
    for (const key in routes) {
        if (routes[key].length > longestRoute.length) {
            longestRoute = routes[key];
        }
    }

    // Ajouter les clients manquants
    const inRoute = new Set(longestRoute);
    for (let i = 1; i < n; i++) {
        if (!inRoute.has(i)) longestRoute.push(i);
    }

    return [0, ...longestRoute];
}

// Or-opt: déplacer des segments de 1, 2 ou 3 clients
function orOptImprovement(route, distMatrix) {
    let improved = true;
    let iterations = 0;
    const maxIterations = 500;

    while (improved && iterations < maxIterations) {
        improved = false;
        iterations++;

        for (let segLen = 1; segLen <= 3; segLen++) {
            for (let i = 1; i < route.length - segLen; i++) {
                for (let j = 1; j < route.length; j++) {
                    if (j >= i && j <= i + segLen) continue;

                    const benefit = orOptMoveBenefit(route, i, segLen, j, distMatrix);
                    if (benefit < -0.001) {
                        route = applyOrOptMove(route, i, segLen, j);
                        improved = true;
                        break;
                    }
                }
                if (improved) break;
            }
            if (improved) break;
        }
    }
    return route;
}

function orOptMoveBenefit(route, i, segLen, j, dist) {
    // Segment à déplacer: route[i] à route[i + segLen - 1]
    const segStart = route[i];
    const segEnd = route[i + segLen - 1];
    const beforeSeg = route[i - 1];
    const afterSeg = route[i + segLen] || null;

    // Coût actuel de retrait du segment
    let currentCost = dist[beforeSeg][segStart];
    if (afterSeg !== null) {
        currentCost += dist[segEnd][afterSeg];
        currentCost -= dist[beforeSeg][afterSeg]; // Nouveau lien après retrait
    }

    // Position d'insertion
    const insertAfter = route[j - 1];
    const insertBefore = route[j] || null;

    // Coût d'insertion
    let insertCost = dist[insertAfter][segStart];
    if (insertBefore !== null) {
        insertCost += dist[segEnd][insertBefore];
        insertCost -= dist[insertAfter][insertBefore];
    }

    return insertCost - currentCost;
}

function applyOrOptMove(route, i, segLen, j) {
    const segment = route.splice(i, segLen);
    const insertPos = j > i ? j - segLen : j;
    route.splice(insertPos, 0, ...segment);
    return route;
}

// 3-opt limité pour amélioration finale
function threeOptImprovement(route, distMatrix) {
    let improved = true;
    let iterations = 0;
    const maxIterations = 100;

    while (improved && iterations < maxIterations) {
        improved = false;
        iterations++;

        for (let i = 1; i < route.length - 2; i++) {
            for (let j = i + 1; j < route.length - 1; j++) {
                for (let k = j + 1; k < route.length; k++) {
                    const improvement = best3OptMove(route, i, j, k, distMatrix);
                    if (improvement.benefit < -0.001) {
                        route = apply3OptMove(route, i, j, k, improvement.moveType);
                        improved = true;
                        break;
                    }
                }
                if (improved) break;
            }
            if (improved) break;
        }
    }
    return route;
}

function best3OptMove(route, i, j, k, dist) {
    const a = route[i - 1], b = route[i];
    const c = route[j - 1], d = route[j];
    const e = route[k - 1], f = route[k] || route[k - 1];

    const d0 = dist[a][b] + dist[c][d] + (k < route.length ? dist[e][f] : 0);

    let bestBenefit = 0;
    let bestMove = 0;

    // Move type 1: reverse segment i to j-1
    const d1 = dist[a][c] + dist[b][d] + (k < route.length ? dist[e][f] : 0);
    if (d1 - d0 < bestBenefit) { bestBenefit = d1 - d0; bestMove = 1; }

    // Move type 2: reverse segment j to k-1
    if (k < route.length) {
        const d2 = dist[a][b] + dist[c][e] + dist[d][f];
        if (d2 - d0 < bestBenefit) { bestBenefit = d2 - d0; bestMove = 2; }
    }

    return { benefit: bestBenefit, moveType: bestMove };
}

function apply3OptMove(route, i, j, k, moveType) {
    if (moveType === 1) {
        const segment = route.slice(i, j).reverse();
        return [...route.slice(0, i), ...segment, ...route.slice(j)];
    } else if (moveType === 2) {
        const segment = route.slice(j, k).reverse();
        return [...route.slice(0, j), ...segment, ...route.slice(k)];
    }
    return route;
}

function greedyInsertionOpenTSP(distMatrix) {
    const n = distMatrix.length;
    if (n <= 2) return Array.from({length: n}, (_, i) => i);

    // Commencer avec dépôt et le client le plus proche
    let route = [0];
    let nearestToDepot = 1;
    let minDist = distMatrix[0][1];
    for (let i = 2; i < n; i++) {
        if (distMatrix[0][i] < minDist) {
            minDist = distMatrix[0][i];
            nearestToDepot = i;
        }
    }
    route.push(nearestToDepot);

    const inRoute = new Set(route);

    // Insérer les autres clients à la position optimale
    while (route.length < n) {
        let bestClient = -1;
        let bestPos = -1;
        let bestCost = Infinity;

        for (let client = 1; client < n; client++) {
            if (inRoute.has(client)) continue;

            // Tester insertion à chaque position
            for (let pos = 1; pos <= route.length; pos++) {
                let cost;
                if (pos === route.length) {
                    // Insertion à la fin
                    cost = distMatrix[route[pos-1]][client];
                } else {
                    // Insertion au milieu
                    const before = route[pos - 1];
                    const after = route[pos];
                    cost = distMatrix[before][client] + distMatrix[client][after] - distMatrix[before][after];
                }

                if (cost < bestCost) {
                    bestCost = cost;
                    bestClient = client;
                    bestPos = pos;
                }
            }
        }

        if (bestClient !== -1) {
            route.splice(bestPos, 0, bestClient);
            inRoute.add(bestClient);
        } else {
            break;
        }
    }

    return route;
}

function openTwoOptImprovement(route, distMatrix) {
    // 2-opt adapté pour Open TSP (pas de retour au dépôt)
    let improved = true;
    let iterations = 0;
    const maxIterations = 1000;

    while (improved && iterations < maxIterations) {
        improved = false;
        iterations++;

        for (let i = 1; i < route.length - 1; i++) {
            for (let j = i + 1; j < route.length; j++) {
                const benefit = openTwoOptSwapBenefit(route, i, j, distMatrix);
                if (benefit < -0.001) {
                    // Faire le swap
                    const newRoute = route.slice(0, i)
                        .concat(route.slice(i, j + 1).reverse())
                        .concat(route.slice(j + 1));
                    route = newRoute;
                    improved = true;
                }
            }
        }
    }
    return route;
}

function openTwoOptSwapBenefit(route, i, j, dist) {
    // Pour Open TSP, on ne considère pas le retour au dépôt
    const before_i = route[i - 1];
    const at_i = route[i];
    const at_j = route[j];

    // Coût actuel du segment
    let currentCost = dist[before_i][at_i];

    // Coût après reverse
    let newCost = dist[before_i][at_j];

    // Si j n'est pas le dernier, considérer aussi la connexion après j
    if (j < route.length - 1) {
        const after_j = route[j + 1];
        currentCost += dist[at_j][after_j];
        newCost += dist[at_i][after_j];
    }

    return newCost - currentCost;
}

// =============================================================================
// ROUTE DRAWING
// =============================================================================

async function drawRealRoute(orderedPoints, route, clients) {
    clearRoute();

    if (osrmConnected) {
        const routeData = await getOSRMRoute(orderedPoints);

        if (routeData && routeData.geometry) {
            const coords = decodePolyline(routeData.geometry);

            // Draw animated path with ant-path
            const antPath = createRouteLine(coords, {
                color: '#1B998B',
                weight: 5,
                opacity: 0.8,
                delay: 1000,
                dashArray: [10, 20],
                pulseColor: '#ffffff'
            }).addTo(map);
            routeLines.push(antPath);
        } else {
            // Fallback to straight lines
            drawStraightRoute(orderedPoints);
        }
    } else {
        drawStraightRoute(orderedPoints);
    }

    // Update markers with order numbers
    clientMarkers.forEach(m => map.removeLayer(m));
    clientMarkers = [];

    route.slice(1).forEach((clientIndex, orderIndex) => {
        const client = clients[clientIndex - 1];
        const icon = L.divIcon({
            html: `<div class="client-marker optimized">${orderIndex + 1}</div>`,
            className: '',
            iconSize: [35, 35],
            iconAnchor: [17, 17]
        });

        const marker = L.marker([client.lat, client.lon], { icon })
            .addTo(map)
            .bindPopup(`
                <div style="font-family: Poppins; min-width: 180px;">
                    <h4 style="color: #00c853; margin: 0 0 10px 0;">✅ Stop #${orderIndex + 1}</h4>
                    <p><b>Commande:</b> ${client.order_id}</p>
                    <p><b>Lat:</b> ${client.lat.toFixed(6)}</p>
                    <p><b>Lon:</b> ${client.lon.toFixed(6)}</p>
                </div>
            `);
        clientMarkers.push(marker);
    });

    fitAllMarkers();
}

function drawStraightRoute(points) {
    const antPath = createRouteLine(points, {
        color: '#f44336',
        weight: 4,
        opacity: 0.7,
        delay: 1000,
        dashArray: [10, 20],
        pulseColor: '#ffffff'
    }).addTo(map);
    routeLines.push(antPath);
}

function displayResults(totalDist, totalTime, orderedClients) {
    const panel = document.getElementById('results-panel');
    panel.style.display = 'block';

    document.getElementById('total-distance').textContent = totalDist.toFixed(2) + ' km';
    document.getElementById('total-time').textContent = Math.round(totalTime) + ' min';
    document.getElementById('num-stops').textContent = orderedClients.length;
    document.getElementById('routing-type').textContent = osrmConnected ? 'OSRM ✓' : 'Haversine';

    const orderContainer = document.getElementById('route-order');
    orderContainer.innerHTML = '<div style="font-weight: 600; margin-bottom: 10px;">Ordre de livraison:</div>';

    orderedClients.forEach((client, index) => {
        orderContainer.innerHTML += `
            <div class="route-item">
                <div class="route-number">${index + 1}</div>
                <div>
                    <div style="font-weight: 600;">${client.order_id}</div>
                    <div style="font-size: 0.75rem; opacity: 0.8;">${client.lat.toFixed(4)}, ${client.lon.toFixed(4)}</div>
                </div>
            </div>
        `;
    });
}

function clearRoute() {
    routeLines.forEach(line => map.removeLayer(line));
    routeLines = [];
    document.getElementById('results-panel').style.display = 'none';
}

function fitAllMarkers() {
    const points = [];

    const depotLat = parseFloat(document.getElementById('depot-lat').value);
    const depotLon = parseFloat(document.getElementById('depot-lon').value);
    points.push([depotLat, depotLon]);

    selectedClients.forEach(index => {
        const client = allClients[index];
        points.push([client.lat, client.lon]);
    });

    if (points.length > 1) {
        map.fitBounds(points, { padding: [50, 50] });
    }
}

// =============================================================================
// UTILITIES
// =============================================================================

function showToast(message, type = '') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = 'toast show ' + type;
    setTimeout(() => toast.className = 'toast', 3000);
}
