# PostgreSQL 16 — Environnement Docker local

Ce dépôt fournit un outil simple permettant de disposer d’un serveur PostgreSQL 16 en local via Docker, sans installer
PostgreSQL sur la machine hôte.

Il s’agit d’un environnement utilitaire, pensé pour être partagé entre plusieurs projets, et capable d’héberger
plusieurs bases de données simultanément.

Ce dépôt n’est pas lié à une application spécifique.

---

## Objectif

- Utiliser PostgreSQL 16 sans installation locale
- Fournir un serveur PostgreSQL unique pour plusieurs projets
- Créer et gérer plusieurs bases de données indépendantes
- Offrir un environnement stable, jetable et reproductible
- Simplifier le travail en développement, formation ou prototypage

---

## Stack technique

- PostgreSQL 16 (image officielle Docker)
- pgAdmin 4 pour l’administration
- Docker
- Docker Compose
- Configuration par variables d’environnement

---

## Prérequis

- Docker installé sur la machine
- Docker Compose v2
- Ports disponibles sur la machine :
  - PostgreSQL : 6432
  - pgAdmin : 6062

---

## Organisation du dépôt

Le dépôt contient uniquement les éléments nécessaires au fonctionnement du serveur PostgreSQL :

- un fichier docker-compose
- un fichier .env-sample servant de modèle
- un fichier .env local non versionné
- ce README

---

## Configuration

Toutes les valeurs configurables sont externalisées dans un fichier .env.

Un fichier .env-sample est fourni comme référence et doit être copié en .env pour un usage local.

Les variables configurables concernent :

- l’utilisateur PostgreSQL
- le mot de passe PostgreSQL
- la base par défaut
- les ports exposés
- les identifiants pgAdmin

Ce serveur PostgreSQL est destiné à héberger plusieurs bases de données.
La variable POSTGRES_DB ne limite pas l’usage à une seule base.

---

## Démarrage

Une fois le fichier .env renseigné, le serveur PostgreSQL et pgAdmin peuvent être démarrés via Docker Compose :
`docker compose up -d`

Après démarrage :

- PostgreSQL écoute sur le port configuré côté hôte
- pgAdmin est accessible via un navigateur web

---

## Utilisation

Ce serveur PostgreSQL est prévu pour :

- créer une base par projet
- créer une base par micro-service
- créer plusieurs bases pour un même projet (développement, test, formation)

Les bases sont créées directement via :

- pgAdmin
- un client SQL
- une application connectée au serveur

Toutes les bases partagent le même serveur PostgreSQL et le même moteur.

---

## pgAdmin

pgAdmin est fourni pour faciliter l’administration :

- création et suppression de bases
- visualisation des schémas
- exécution de requêtes SQL
- inspection des connexions

Lors de l’ajout du serveur PostgreSQL dans pgAdmin :

- l’hôte à utiliser est le nom du service Docker
- le port PostgreSQL interne est 5432
- les identifiants sont ceux définis dans le fichier .env

---

## Données et persistance

Les données PostgreSQL sont persistées dans un volume Docker.

Cela signifie que :

- les données survivent aux redémarrages
- les données sont conservées tant que le volume existe

Pour repartir d’un environnement totalement vierge, le volume peut être supprimé volontairement.

Cette opération efface toutes les bases de données.

---

## Pourquoi PostgreSQL 16

PostgreSQL ne définit pas officiellement de version LTS, mais chaque version majeure est maintenue environ cinq ans.

PostgreSQL 16 est :

- moderne
- stable
- largement adopté
- adapté à des projets actuels et futurs

C’est un bon compromis entre longévité et fonctionnalités.

---

## Bonnes pratiques

- Utiliser une base par projet
- Ne pas partager une même base entre plusieurs applications
- Ne pas utiliser l’image Docker latest
- Centraliser les identifiants dans le fichier .env
- Utiliser cet environnement uniquement en local ou en environnement de travail

---

## Contribuer

Les contributions sont bienvenues.

Le dépôt est volontairement simple, mais peut évoluer (healthcheck, timezone, profils Docker, documentation, etc.).

Pour contribuer :

- forker le dépôt
- créer une branche dédiée
- proposer des changements clairs et documentés
- ouvrir une pull request

Toute contribution doit rester cohérente avec l’objectif initial : un outil simple, lisible et libre.

---

## Auteur

Nicolas Vauché  
Contact : hello@nicolasvauche.net

---

## Licence

Ce projet est distribué sous licence GNU General Public License v3 (GPLv3).

Cela signifie notamment que :

- le code peut être utilisé, modifié et redistribué librement
- toute redistribution ou modification doit rester sous licence GPLv3
- le projet et ses dérivés doivent rester dans le logiciel libre

Cette licence garantit que l’outil restera libre et ouvert dans le temps.
