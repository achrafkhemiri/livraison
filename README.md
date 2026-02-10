# Smart Delivery OSRM — Instructions

## 1) Utilité de `data.ipynb`

`data.ipynb` contient les notebooks d'expérimentation et les utilitaires Python utilisés pendant le développement :

- Classes et wrappers pour appeler OSRM (`OSRMRealRouter`).
- Optimiseur VRP/OTSP (heuristiques et techniques d'amélioration) (`EnhancedVRPOptimizer`).
- Génération de cartes interactives/folium (`RealRouteMapGenerator`).
- Tests, visualisations et expériences (comparaison Haversine vs OSRM, diagnostics).

Est-ce nécessaire pour exécuter l'interface web ?
- Non, pas obligatoire : l'interface web (`smart_delivery_osrm.html`) utilise directement l'OSRM local via HTTP et les scripts JavaScript embarqués. Vous pouvez lancer l'interface et OSRM sans ouvrir le notebook.
- Oui, utile : gardez `data.ipynb` pour reproduire expériences, créer jeux de données, tester l'optimiseur en Python, ou générer cartes `.html`/rapports. C'est précieux pour développement et debug.

Recommandation : conservez `data.ipynb` pour développement et audits, mais il n'est pas requis pour la mise en production du front-end statique + OSRM.

---

## 2) Pré-requis (local)

- Docker installé
- Python 3.8+ si vous voulez exécuter le notebook
- Les fichiers de données OSRM (fichiers `.osm.pbf` ou les fichiers `.osrm` déjà préparés) dans un dossier local accessible par Docker

Recommandation de paquets Python (pour notebook) :

```powershell
pip install pandas numpy folium ortools requests polyline matplotlib scipy jupyterlab
```

---

## 3) Commandes Docker pour préparer et lancer OSRM

Remplacez `C:\path\to\data` par le dossier Windows contenant vos fichiers `.osm.pbf` ou vos fichiers `.osrm`.

Étape A — Si vous avez un fichier OSM brut (`tunisia-latest.osm.pbf`) :

1) Extraire (profil `car` par défaut) :

```powershell
docker run --rm -t -v C:\path\to\data:/data osrm/osrm-backend:latest \
  osrm-extract -p /opt/car.lua /data/tunisia-latest.osm.pbf
```

2) Construire les structures (CH) :

```powershell
docker run --rm -t -v C:\path\to\data:/data osrm/osrm-backend:latest \
  osrm-contract /data/tunisia-latest.osrm
```

> Alternative MLD (si vous préférez MLD) :
> ```powershell
> docker run --rm -t -v C:\path\to\data:/data osrm/osrm-backend:latest osrm-partition /data/tunisia-latest.osrm
> docker run --rm -t -v C:\path\to\data:/data osrm/osrm-backend:latest osrm-customize /data/tunisia-latest.osrm
> ```

3) Lancer le serveur OSRM (CH) :

```powershell
docker run -d --name osrm-tunisia -p 5000:5000 -v C:\path\to\data:/data osrm/osrm-backend:latest \
  osrm-routed --algorithm ch /data/tunisia-latest.osrm
```

- Si vous avez préparé les fichiers `.osrm` dans le dossier, sautez les étapes d'extract/contract et lancez directement `osrm-routed`.
- Pour MLD, omettez `--algorithm ch` et fournissez le fichier `.osrm` :

```powershell
docker run -d --name osrm-tunisia -p 5000:5000 -v C:\path\to\data:/data osrm/osrm-backend:latest \
  osrm-routed /data/tunisia-latest.osrm
```

Vérifier le conteneur :

```powershell
docker ps
# ou
docker logs osrm-tunisia --tail 50
```

Tester une requête de sanity-check (PowerShell) :

```powershell
Invoke-RestMethod "http://localhost:5000/route/v1/driving/10.7600,34.7400;10.7548,34.7421"
```

Si la réponse JSON contient `code: "Ok"` et `routes`, OSRM est opérationnel.

---

## 4) Lancer l'interface web (front-end)

L'approche la plus simple pour éviter des problèmes CORS en mode `file://` est d'héberger les fichiers statiques via un serveur HTTP local.

Option A — Serveur Python (rapide) :

```powershell
# depuis le dossier contenant smart_delivery_osrm.html
python -m http.server 8000
# puis ouvrez dans le navigateur:
http://localhost:8000/smart_delivery_osrm.html
```

Option B — Ouvrir directement (Windows) :

```powershell
Start-Process "C:\Users\USER\Desktop\Nouveau dossier (2)\smart_delivery_osrm.html"
```

> Remarque : si votre navigateur bloque certaines requêtes fetch() en `file://`, utilisez `python -m http.server`.

---

## 5) Vérifications rapides

- OSRM sur : http://localhost:5000
- Tester route simple :

```powershell
# Example
Invoke-RestMethod "http://localhost:5000/route/v1/driving/10.7600,34.7400;10.7548,34.7421"
```

- Ouvrir l'interface : http://localhost:8000/smart_delivery_osrm.html (ou ouvrir localement)
- Dans l'interface : vérifier que le statut OSRM est vert (OSRM Connecté ✓)

---

## 6) Utilisation du notebook `data.ipynb` (si désiré)

- Ouvrez Jupyter Lab / Notebook :

```powershell
jupyter lab
# ou
jupyter notebook
```

- Exécutez les cellules dans l'ordre. Les principales utilités :
  - Générer des cartes folium plus détaillées
  - Tester des variantes d'optimisation en Python
  - Exporter des jeux de données (CSV) pour l'UI

---

## 7) Dépannage

- Si OSRM répond mais l'interface affiche "OSRM non disponible": vérifiez que le navigateur peut atteindre `http://localhost:5000` (pare-feu) et que le port 5000 est exposé.
- Si les distances semblent incohérentes, vérifiez que l'image OSRM et les fichiers `.osrm` ont été générés pour le profil voulu (`car.lua` par défaut).

---

## 8) Notes finales

- `data.ipynb` = utile pour développement, analyses et génération de cartes/rapports.
- `smart_delivery_osrm.html` + OSRM = ensemble suffisant pour l'affichage interactif et le calcul d'itinéraires en production légère.

Si vous voulez, je peux aussi :
- Ajouter un `requirements.txt` pour reproduire l'environnement Python du notebook.
- Générer un script PowerShell `start-osrm.ps1` qui exécute les étapes de lancement (extract/contract/run) automatisées.

