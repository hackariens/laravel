CREATE DATABASE IF NOT EXISTS `laravel_bdd`;
CREATE USER IF NOT EXISTS 'laravel'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON `laravel_bdd`.* TO 'laravel'@'%';