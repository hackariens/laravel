#!/bin/bash

# Script d'initialisation pour Laravel dans Docker
# Gère les permissions et l'installation des dépendances

echo "Initialisation de Laravel..."

# Installation des dépendances Composer si nécessaire
if [ ! -d "/var/www/vendor" ] || [ ! -f "/var/www/vendor/autoload.php" ]; then
    echo "Installation des dépendances Composer..."
    cd /var/www && composer install --no-dev --optimize-autoloader
fi

# Création des répertoires nécessaires s'ils n'existent pas
mkdir -p /var/www/storage/framework/views
mkdir -p /var/www/storage/framework/cache
mkdir -p /var/www/storage/framework/sessions
mkdir -p /var/www/storage/logs
mkdir -p /var/www/bootstrap/cache

# Configuration des permissions
echo "Configuration des permissions..."
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Configuration des permissions pour la base de données SQLite
if [ -f "/var/www/database/database.sqlite" ]; then
    echo "Configuration des permissions pour la base de données SQLite..."
    chown www-data:www-data /var/www/database/database.sqlite
    chmod 664 /var/www/database/database.sqlite
    # Le répertoire database doit aussi être accessible en écriture pour SQLite
    chown www-data:www-data /var/www/database
    chmod 775 /var/www/database
fi

# Génération de la clé d'application si nécessaire
if [ ! -f "/var/www/.env" ]; then
    echo "Copie du fichier .env..."
    cp /var/www/.env.example /var/www/.env
    cd /var/www && php artisan key:generate
fi

# Optimisation pour la production
cd /var/www
php artisan config:clear
php artisan route:clear  
php artisan view:clear
php artisan cache:clear

echo "Initialisation terminée!"