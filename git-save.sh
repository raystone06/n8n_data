#!/bin/bash

# Chemin vers votre dépôt Git
REPO_PATH="/var/lib/docker/volumes/n8n_data/_data"

# Se déplacer vers le répertoire du dépôt
cd $REPO_PATH || exit 1

# Ajouter tous les fichiers modifiés
git add .

# Vérifier s'il y a des modifications à commiter
if git diff --staged --quiet; then
    echo "Aucune modification à pousser $(date)"
    exit 0
fi

# Créer un commit avec la date actuelle
git commit -m "Sauvegarde automatique $(date +"%Y-%m-%d %H:%M:%S")"

# Essayer de pousser les modifications
git push origin main || {
    # En cas d'échec, tirer les changements puis repousser
    git pull --rebase origin main && git push origin main
}
