# Docker & PostgreSQL + PGAdmin4 + Adminer
Installation d'un environnement PostgreSQL avec PGAdmin et Adminer.

## Installation
Dupliquer le fichier `.env-sample` et le renommer en `.env`  
Renseigner vos informations dans le fichier `.env`  

Monter les conteneurs Docker (PostgreSQL, PGAdmin, Adminer) :  
`docker compose up`

## Utilisation
- PostgreSQL Host : `127.0.0.1:[VOTRE_DB_PORT]`  
- PGAdmin4 : http://127.0.0.1:[VOTRE_PGADMIN_PORT]  
- Adminer: http://127.0.0.1:[VOTRE_ADMINER_PORT]  
