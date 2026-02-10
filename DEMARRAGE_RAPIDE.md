# 🚀 Démarrage Rapide — Smart Delivery OSRM

Guide pour relancer le projet après avoir fermé le PC.

---

## Étape 1 : Démarrer Docker Desktop

1. Ouvrez **Docker Desktop** sur Windows
2. Attendez que Docker soit prêt (icône verte dans la barre des tâches)

---

## Étape 2 : Démarrer le conteneur OSRM

Ouvrez **PowerShell** et exécutez :

```powershell
docker start osrm-tunisia
```

**Vérifier que le conteneur est lancé :**

```powershell
docker ps
```

Vous devriez voir `osrm-tunisia` dans la liste avec le statut `Up`.

**Voir les logs (optionnel) :**

```powershell
docker logs osrm-tunisia --tail 50
```

---

## Étape 3 : Tester la connexion OSRM

Dans PowerShell, testez une requête :

```powershell
Invoke-RestMethod "http://localhost:5000/route/v1/driving/10.7600,34.7400;10.7548,34.7421"
```

✅ Si vous recevez une réponse JSON avec `"code": "Ok"`, OSRM fonctionne !

❌ Si erreur "connexion refusée" :
- Vérifiez que Docker Desktop est lancé
- Vérifiez que le conteneur `osrm-tunisia` est en cours d'exécution (`docker ps`)

---

## Étape 4 : Ouvrir l'interface web

### Option A : Ouvrir directement le fichier HTML

```powershell
Start-Process "C:\Users\USER\Desktop\Nouveau dossier (2)\smart_delivery_osrm.html"
```

### Option B : Utiliser un serveur HTTP local (recommandé)

```powershell
cd "C:\Users\USER\Desktop\Nouveau dossier (2)"
python -m http.server 8000
```

Puis ouvrez dans votre navigateur :
```
http://localhost:8000/smart_delivery_osrm.html
```

---

## Étape 5 : Vérifier la connexion dans l'interface

1. L'interface devrait s'ouvrir dans le navigateur
2. Regardez en haut à gauche : **indicateur OSRM**
3. Si le point est **vert** avec "OSRM Connecté ✓" → tout fonctionne ! 🎉
4. Si le point est **rouge** → vérifiez les étapes 2 et 3

---

## Utilisation

1. **Sélectionnez les clients** dans la liste (cochez les cases)
2. Ou cliquez sur **"Tout"** pour sélectionner tous les clients
3. Cliquez sur **"Trouver le plus court chemin"**
4. Attendez le calcul (quelques secondes)
5. La route optimale s'affiche sur la carte ! 🗺️

---

## Arrêter le projet

Quand vous avez terminé :

### Arrêter le conteneur OSRM :

```powershell
docker stop osrm-tunisia
```

### Fermer le serveur Python (si utilisé) :

Appuyez sur `Ctrl+C` dans le terminal PowerShell où tourne le serveur.

### Fermer Docker Desktop :

Clic droit sur l'icône Docker dans la barre des tâches → Quit Docker Desktop

---

## Problèmes fréquents

| Problème | Solution |
|----------|----------|
| "OSRM non disponible" (point rouge) | `docker start osrm-tunisia` |
| Le conteneur n'existe pas | Relancez la commande complète dans `README.md` section 3 |
| Port 5000 déjà utilisé | Arrêtez l'autre processus ou changez le port : `-p 5001:5000` |
| Interface ne charge pas | Utilisez `python -m http.server 8000` au lieu d'ouvrir directement |
| Erreur CORS | Utilisez le serveur HTTP local (Option B) |

---

## Commandes rapides (copier-coller)

**Tout démarrer :**
```powershell
# 1. Démarrer OSRM
docker start osrm-tunisia

# 2. Vérifier
docker ps

# 3. Lancer l'interface (Option A)
Start-Process "C:\Users\USER\Desktop\Nouveau dossier (2)\smart_delivery_osrm.html"

# OU (Option B - recommandé)
cd "C:\Users\USER\Desktop\Nouveau dossier (2)"
python -m http.server 8000
# Puis ouvrir : http://localhost:8000/smart_delivery_osrm.html
```

**Tout arrêter :**
```powershell
docker stop osrm-tunisia
```

---

## Prochaines étapes

Pour modifier les clients, éditez le fichier `sf_dataset.csv` et rechargez l'interface, ou utilisez le bouton **"Ajouter un client"** directement dans l'interface.

Bon travail ! 🚚✨
