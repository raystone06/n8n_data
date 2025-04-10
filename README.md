# Sauvegarde n8n

Ce dépôt contient les sauvegardes automatiques des données de l'instance n8n. La dernière sauvegarde a été effectuée le **10 April 2025 à 06:34:02 (UTC)**.

## Procédure de restauration des données

Pour restaurer ces données dans une nouvelle installation de n8n, suivez ces étapes :

### 1. Cloner le dépôt

```bash
# Créez un répertoire temporaire et clonez le dépôt
mkdir -p /tmp/n8n-restore
cd /tmp/n8n-restore
git clone https://github.com/raystone06/n8n_data.git
```

### 2. Arrêter le conteneur n8n existant (si nécessaire)

```bash
# Arrêtez le conteneur n8n si vous en avez déjà un qui fonctionne
docker stop n8n
docker rm n8n
```

### 3. Restaurer les données

```bash
# Créez le volume Docker s'il n'existe pas déjà
docker volume create n8n_data

# Copiez les données du dépôt vers le volume Docker
# ATTENTION: Cette commande écrasera toutes les données existantes dans le volume
sudo rsync -av --delete /tmp/n8n-restore/n8n_data/ /var/lib/docker/volumes/n8n_data/_data/
```

### 4. Démarrer le conteneur n8n avec le volume restauré

```bash
docker run -d \
  --name n8n \
  --restart=always \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e GENERIC_TIMEZONE="Africa/Abidjan" \
  -e TZ="Africa/Abidjan" \
  -e N8N_PORT=5678 \
  -e NODE_ENV=production \
  -e N8N_SECURE_COOKIE=false \
  -e N8N_PUSH_BACKEND=sse \
  docker.n8n.io/n8nio/n8n
```

### 5. Vérifier l'installation

Accédez à votre instance n8n via `http://votre-serveur:5678` et vérifiez que tous vos workflows et configurations ont été correctement restaurés.

## Notes importantes

- Cette sauvegarde contient la base de données SQLite, les fichiers de configuration et les journaux d'événements de n8n.
- Les modifications de permissions peuvent être nécessaires selon votre système:
  ```bash
  sudo chown -R 1000:1000 /var/lib/docker/volumes/n8n_data/_data/
  ```
- Assurez-vous que votre nouvelle installation de n8n utilise la même version que celle utilisée lors de la sauvegarde, ou une version compatible.
- Si vous utilisez d'autres variables d'environnement dans votre configuration, assurez-vous de les inclure dans la commande de démarrage du conteneur.

## Informations sur la sauvegarde automatique

Ce dépôt est mis à jour automatiquement par un script cron qui s'exécute sur le serveur n8n. Pour configurer un système similaire de sauvegarde automatique sur GitHub, consultez les détails dans le script [git-save.sh](https://github.com/raystone06/n8n_data/blob/main/git-save.sh).
