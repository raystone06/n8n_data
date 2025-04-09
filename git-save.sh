#!/bin/bash

# Répertoire où monter le volume Docker
BACKUP_DIR="/root/n8n-backup"
# Répertoire du volume Docker
VOLUME_DATA="/var/lib/docker/volumes/n8n_data/_data"
# Date et heure actuelles en GMT+0 (UTC)
CURRENT_DATE=$(date -u '+%d %B %Y à %H:%M:%S (UTC)')
# Message de commit
COMMIT_MSG="Sauvegarde automatique n8n $(date '+%Y-%m-%d %H:%M:%S')"
# Information Git
GIT_EMAIL="rlaurent50.rl@gmail.com"
GIT_USERNAME="raystone06"
GIT_REPO="https://github.com/raystone06/n8n_data.git"

# Assurez-vous que le répertoire de sauvegarde existe
mkdir -p $BACKUP_DIR

# Créer un répertoire temporaire pour stocker les données
TMP_DIR="/tmp/n8n-data-tmp"
mkdir -p $TMP_DIR

# Copier les données du volume vers le répertoire temporaire
rsync -av --delete $VOLUME_DATA/ $TMP_DIR/

# Configurer le dépôt Git
cd $BACKUP_DIR

# Résoudre le problème de propriété "dubious ownership"
git config --global --add safe.directory $BACKUP_DIR

# Si ce n'est pas déjà un repo git, l'initialiser
if [ ! -d "$BACKUP_DIR/.git" ]; then
  git init
  # Configurer le Git global pour l'utilisateur root
  git config --global user.email "$GIT_EMAIL"
  git config --global user.name "$GIT_USERNAME"
  # Configurer le branche principale comme 'main'
  git config --global init.defaultBranch main
  
  # Ajouter et commiter un README initial
  cat > README.md << EOF
# Sauvegarde n8n

Ce dépôt contient les sauvegardes automatiques des données de n8n. La dernière sauvegarde a été effectuée le **$CURRENT_DATE**.

## Procédure de restauration des données

Pour restaurer ces données dans une nouvelle installation de n8n, suivez ces étapes :

### 1. Cloner le dépôt

\`\`\`bash
# Créez un répertoire temporaire et clonez le dépôt
mkdir -p /tmp/n8n-restore
cd /tmp/n8n-restore
git clone https://github.com/raystone06/n8n_data.git
\`\`\`

### 2. Restaurer les données

\`\`\`bash
# Créez le volume Docker s'il n'existe pas déjà
docker volume create n8n_data

# Copiez les données du dépôt vers le volume Docker
# ATTENTION: Cette commande écrasera toutes les données existantes dans le volume
sudo rsync -av --delete /tmp/n8n-restore/n8n_data/ /var/lib/docker/volumes/n8n_data/_data/
\`\`\`

### 4. Démarrer le conteneur n8n avec le volume restauré

\`\`\`bash
docker run -d \\
  --name n8n \\
  --restart=always \\
  -p 5678:5678 \\
  -v n8n_data:/home/node/.n8n \\
  -e GENERIC_TIMEZONE="Africa/Abidjan" \\
  -e TZ="Africa/Abidjan" \\
  -e N8N_PORT=5678 \\
  -e NODE_ENV=production \\
  -e N8N_SECURE_COOKIE=false \\
  -e N8N_PUSH_BACKEND=sse \\
  docker.n8n.io/n8nio/n8n
\`\`\`

### 5. Vérifier l'installation

Accédez à votre instance n8n via \`http://votre-serveur:5678\` et vérifiez que tous vos workflows et configurations ont été correctement restaurés.

## Notes importantes

- Cette sauvegarde contient la base de données SQLite, les fichiers de configuration et les journaux d'événements de n8n.
- Les modifications de permissions peuvent être nécessaires selon votre système:
  \`\`\`bash
  sudo chown -R 1000:1000 /var/lib/docker/volumes/n8n_data/_data/
  \`\`\`
- Assurez-vous que votre nouvelle installation de n8n utilise la même version que celle utilisée lors de la sauvegarde, ou une version compatible.
- Si vous utilisez d'autres variables d'environnement dans votre configuration, assurez-vous de les inclure dans la commande de démarrage du conteneur.

## Informations sur la sauvegarde automatique

Ce dépôt est mis à jour automatiquement par un script cron qui s'exécute sur le serveur n8n.

### Configuration du cron

Pour exécuter la sauvegarde automatique chaque minute, ajoutez cette ligne dans votre crontab :

\`\`\`bash
# Éditer le crontab
crontab -e

# Ajouter cette ligne pour exécuter le script chaque minute
* * * * * /root/n8n-backup/git-save.sh >> /var/log/n8n-backup.log 2>&1
\`\`\`
EOF
  
  git add README.md
  git commit -m "Initial commit"
  
  # Connecter au dépôt distant
  git remote add origin $GIT_REPO
fi

# Copier les fichiers du répertoire temporaire vers le dépôt Git
# IMPORTANT: Exclure le dossier .git pour ne pas écraser la configuration Git
rsync -av --exclude='.git' $TMP_DIR/ $BACKUP_DIR/

# Mettre à jour le README.md avec la nouvelle date de sauvegarde
sed -i "s/La dernière sauvegarde a été effectuée le \*\*.*\*\*/La dernière sauvegarde a été effectuée le \*\*$CURRENT_DATE\*\*/" $BACKUP_DIR/README.md

# Vérifier s'il y a des changements à committer
if [[ $(git status --porcelain) ]]; then
  # Il y a des changements, faire un commit
  git add .
  git commit -m "$COMMIT_MSG"
  
  # Récupérer les changements distants avant de pousser
  git pull --rebase origin main
  
  # Essayer de pousser vers GitHub
  if git push origin main; then
    echo "Sauvegarde réussie vers GitHub à $(date)"
  else
    echo "Erreur lors du push vers GitHub à $(date). Vérifiez vos identifiants."
  fi
else
  echo "Aucun changement détecté à $(date)"
fi

# Nettoyer le répertoire temporaire
rm -rf $TMP_DIR
