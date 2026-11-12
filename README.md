# docker_postgresql

Environnement PostgreSQL pour le développement local sous Windows avec Docker
Desktop. PostgreSQL **16 par défaut**, version configurable, stockage dans un
volume Linux, commandes PowerShell et sauvegardes au format natif PostgreSQL.
Aucune installation de PostgreSQL sur Windows n'est nécessaire.
Cet environnement est autonome et utilisable avec tout client ou application
compatible PostgreSQL, quel que soit son langage ou son framework.

> [!WARNING]
> **Cet environnement est réservé au développement local et à l'apprentissage. Ne l'utilisez pas tel quel en production.**
> Le compte créé dispose des droits superutilisateur, le mot de passe est stocké
> dans `.env`, et aucune configuration TLS ni sauvegarde automatique n'est prévue.
> Un déploiement en production nécessite une configuration dédiée, notamment pour
> limiter les droits d'accès, gérer les secrets, sécuriser les connexions et mettre
> en place des sauvegardes dont la restauration est vérifiée.

## Prérequis

- Docker Desktop démarré en mode conteneurs Linux, avec WSL2 sous Windows.
- Docker Compose v2 récent prenant en charge `up --wait` et `config --format json`.
- Windows PowerShell 5.1 ou PowerShell 7 (également utilisable sous Linux/macOS).
- Internet pour télécharger les images lors du premier lancement et des mises à jour.

## Récupérer le projet pour un cours

Téléchargez l'archive ZIP du dépôt ou de la release indiquée par votre enseignant,
puis extrayez-la entièrement dans un dossier de travail sur votre ordinateur.
Ouvrez le dossier extrait contenant `README.md`, `dev.ps1` et `compose.yaml` :
il peut s'appeler `docker_postgresql-main` ou porter un numéro de version.
Dans ce guide, `docker_postgresql` désigne ce dossier, quel que soit son nom réel.
Vous devez conserver les sous-dossiers, notamment `docker/init/`.

Git n'est pas nécessaire pour utiliser l'archive. Si vous préférez cloner le
dépôt, utilisez son URL fournie par votre enseignant. Aucun framework, PHP,
Composer ou projet applicatif n'est requis. Le client SQL `psql` est inclus
dans le conteneur ; un logiciel graphique reste facultatif.

Chaque étudiant exécute sa propre instance locale. Pour un premier exercice,
conservez les valeurs par défaut, suivez « Installation », puis ouvrez la
console avec `.\dev.ps1 psql` depuis le dossier extrait. Dans cette console,
exécutez `SELECT current_database(), current_user;`, puis saisissez `\q` pour
revenir à PowerShell. À la fin de la séance, `.\dev.ps1 stop` conserve le travail
en base ; à la séance suivante, `.\dev.ps1 start` le retrouve.

## Installation

Ouvrez PowerShell à la racine du dossier `docker_postgresql`, là où se trouvent
`dev.ps1` et `compose.yaml`. Sauf indication contraire, toutes les commandes de
ce README sont à exécuter dans ce terminal, depuis ce dossier. Dans les
explications, le préfixe `docker_postgresql/` identifie ce dossier :
`docker_postgresql/.env` désigne donc le fichier `.env` à sa racine, pas un
sous-dossier supplémentaire. Les chemins dans les commandes sont relatifs au
dossier indiqué pour leur exécution.

Créez d'abord la configuration locale :

```powershell
.\dev.ps1 init
```

Si vous souhaitez personnaliser l'installation, ouvrez maintenant le fichier
`docker_postgresql/.env` dans votre éditeur. Modifiez les lignes
`POSTGRES_VERSION`, `POSTGRES_PORT`, `POSTGRES_USER` et `POSTGRES_DB` selon vos
besoins, puis enregistrez le fichier. La section « Configuration » détaille ces
valeurs. Démarrez ensuite PostgreSQL :

```powershell
.\dev.ps1 start
.\dev.ps1 check
```

`init` crée `docker_postgresql/.env` depuis `docker_postgresql/.env.example`,
avec un mot de passe aléatoire de 48 caractères hexadécimaux. Il ne remplace
jamais un `.env` existant. Si vous
copiez le modèle manuellement vers `.env` dans le même dossier, renseignez
vous-même la ligne `POSTGRES_PASSWORD` dans ce nouveau fichier : une valeur vide
bloque le démarrage. Le mot de passe généré se consulte également à la ligne
`POSTGRES_PASSWORD` du fichier `docker_postgresql/.env`.

`start` démarre en arrière-plan et attend que PostgreSQL soit prêt (120 secondes
maximum). Le terminal peut ensuite être fermé. Aucun Dockerfile n'est nécessaire :
l'image officielle `postgres` est utilisée directement, dans sa variante Bookworm.

Si Windows bloque le script, utilisez ponctuellement :

```powershell
powershell -ExecutionPolicy Bypass -File .\dev.ps1 init
powershell -ExecutionPolicy Bypass -File .\dev.ps1 start
```

## Configuration

Les variables ci-dessous se configurent dans **`docker_postgresql/.env`**, à côté
de `compose.yaml`. Modifiez les lignes existantes plutôt que d'en ajouter des
doublons. Enregistrez vos changements avant de lancer les commandes Docker.

| Variable | Valeur par défaut | Fonction |
| --- | --- | --- |
| `POSTGRES_VERSION` | `16` | Version majeure ou exacte, par exemple `16.15` |
| `POSTGRES_PORT` | `5432` | Port sur Windows, publié sur `127.0.0.1` uniquement |
| `POSTGRES_USER` | `app` | Superutilisateur créé à la première initialisation |
| `POSTGRES_DB` | `app` | Base créée à la première initialisation |
| `POSTGRES_PASSWORD` | aucune | Mot de passe obligatoire, généré par `init` |
| `COMPOSE_PROJECT_NAME` | nom du dossier | Identité des conteneurs, réseau et volume |

Le fichier `docker_postgresql/.env.example` est un modèle ; le modifier après
`init` ne change pas votre configuration locale. Compose lit `docker_postgresql/.env`.
Les variables du terminal sont prioritaires. Les valeurs contenant `$` doivent
être entourées d'apostrophes dans
`.env` pour éviter l'interpolation. Le mot de passe généré n'en contient pas.

Le script accepte les versions numériques majeures ou exactes ; `latest`, `stable`,
les préversions et les suffixes personnalisés sont refusés. Le tag correspondant
doit exister dans l'image officielle, sinon Docker échoue sans repli silencieux.
Les versions 16, 17 et 18 font partie de la matrice de tests.

Le tag `16` suit les correctifs de la branche 16 lorsque vous téléchargez une
nouvelle image. Un tag exact fixe le correctif PostgreSQL, mais reste susceptible
de recevoir des reconstructions système ; il ne constitue pas un verrou par digest.

Les variables `POSTGRES_USER`, `POSTGRES_DB` et `POSTGRES_PASSWORD` initialisent
uniquement un volume vide. Les modifier dans `.env` **ne modifie pas une base
existante**.

Pour changer le mot de passe du compte existant :

1. Avec PostgreSQL démarré et les valeurs `POSTGRES_USER` et `POSTGRES_DB`
   correspondant au volume existant dans `docker_postgresql/.env`, lancez
   `.\dev.ps1 psql` dans le terminal PostgreSQL.
2. Dans la console SQL qui s'ouvre, saisissez `\password`, puis le nouveau mot
   de passe aux deux invites. Saisissez `\q` pour revenir à PowerShell.
3. Dans `docker_postgresql/.env`, remplacez la valeur de `POSTGRES_PASSWORD`
   par ce même mot de passe et enregistrez le fichier.
4. Lancez `.\dev.ps1 start` pour actualiser l'environnement du conteneur, puis
   `.\dev.ps1 check` pour vérifier réellement l'authentification TCP.
5. Modifiez le mot de passe dans les paramètres de connexion de vos clients.
   Mettez également à jour les identifiants de vos applications dans leur propre
   configuration de connexion, puis appliquez ces changements selon leur
   procédure habituelle de redémarrage ou de rechargement.

## Commandes

```powershell
.\dev.ps1 start                 # Démarre et attend l'état sain
.\dev.ps1 status                # Affiche l'état et le port publié
.\dev.ps1 check                 # Vérifie connexion, authentification et SQL
.\dev.ps1 logs                  # Suit les 100 dernières lignes puis les suivantes
.\dev.ps1 psql                  # Console SQL ; quitter avec \q
.\dev.ps1 psql -c 'SELECT now();'
.\dev.ps1 backup                # Sauvegarde la base POSTGRES_DB
.\dev.ps1 stop                  # Arrête et retire les conteneurs, conserve les données
```

Les chemins fournis à `restore` sont relatifs au dossier de cet environnement,
même si vous invoquez le script depuis un autre dossier. Les erreurs SQL et Docker
sont propagées, sans afficher le mot de passe dans les messages du script.

Compose reste utilisable directement après `init` :

```powershell
docker compose config --quiet
docker compose up -d --wait
docker compose down
```

`docker compose config` sans `--quiet` affiche notamment les secrets résolus :
ne partagez pas sa sortie complète.

## Connexion depuis Windows

Dans votre IDE, DBeaver, pgAdmin ou autre client PostgreSQL, créez une connexion
PostgreSQL et renseignez les champs suivants dans ses paramètres. Reprenez les
valeurs de votre fichier `docker_postgresql/.env` :

- Hôte : `127.0.0.1`.
- Port : `5432` ou la valeur `POSTGRES_PORT`.
- Base : valeur de `POSTGRES_DB` (`app` par défaut).
- Utilisateur : valeur de `POSTGRES_USER` (`app` par défaut).
- Mot de passe : valeur de `POSTGRES_PASSWORD`.
- TLS : non configuré dans cet environnement local.

## Connexion depuis une application Docker

Cet environnement est indépendant de votre application et de son framework.
Pour qu'un autre conteneur accède à PostgreSQL, raccordez-le au réseau de cet
environnement. Le port publié sur Windows n'est pas utilisé pour cette connexion.

Démarrez d'abord PostgreSQL avec `.\dev.ps1 start` depuis `docker_postgresql`.
Avec le nom de projet par défaut, son réseau s'appelle
`docker_postgresql_default` si le dossier s'appelle `docker_postgresql`.
Pour un dossier extrait sous un autre nom, le préfixe suit ce nom de projet
Compose ; `.\dev.ps1 status` affiche les noms des conteneurs correspondants.
Pour choisir un nom prévisible, définissez `COMPOSE_PROJECT_NAME` avant le premier
démarrage comme expliqué dans « Plusieurs projets ».
Si vous avez défini `COMPOSE_PROJECT_NAME=cours-blog-db`
dans `docker_postgresql/.env`, son réseau s'appelle `cours-blog-db_default`.

Dans le **fichier Compose de votre application**, généralement `compose.yaml`
à la racine de son propre projet, ajoutez le réseau externe et rattachez-y le
service qui doit accéder à la base. Voici les éléments à intégrer à votre
configuration existante ; `application` est un nom d'exemple à remplacer par
le nom réel de votre service :

```yaml
services:
  application:
    # Conservez ici l'image, les volumes et les autres paramètres existants.
    networks:
      - default
      - postgresql

networks:
  postgresql:
    external: true
    name: docker_postgresql_default
```

Fusionnez ces éléments avec les sections `services` et `networks` déjà présentes,
sans créer de clés en double. Conservez les réseaux déjà utilisés par votre
service ; `default` correspond au réseau implicite habituel de Compose.
Dans ce même fichier, adaptez `networks.postgresql.name` au nom du réseau
PostgreSQL déterminé ci-dessus. Raccordez également les éventuels services
séparés qui exécutent des tâches ou des migrations nécessitant la base.

Dans les paramètres de connexion de votre application, utilisez :

- Hôte : `postgres`, le nom du service PostgreSQL sur le réseau partagé.
- Port : `5432`, même si `POSTGRES_PORT` vaut autre chose sur Windows.
- Base, utilisateur et mot de passe : valeurs de `POSTGRES_DB`, `POSTGRES_USER`
  et `POSTGRES_PASSWORD` dans `docker_postgresql/.env`.

Le nom des paramètres et le fichier où les renseigner dépendent de votre
application : consultez sa documentation de configuration PostgreSQL. Cet
environnement n'impose ni fichier applicatif `.env` ni variable `DATABASE_URL`.
Si votre application accepte une URI PostgreSQL, sa forme est par exemple
`postgresql://app:MOT_DE_PASSE@postgres:5432/app` : remplacez l'utilisateur,
le mot de passe et la base par vos valeurs. Encodez les caractères réservés
si nécessaire ; le mot de passe hexadécimal généré fonctionne tel quel.

Enregistrez le fichier Compose de l'application, puis appliquez-le avec sa
commande habituelle de démarrage, depuis le dossier de cette application.
Le réseau PostgreSQL doit déjà exister. Pour arrêter les deux environnements,
arrêtez et retirez d'abord les conteneurs de l'application raccordés à ce réseau,
puis lancez `.\dev.ps1 stop` depuis `docker_postgresql`.

## Données et initialisation

Le volume nommé `postgres_data`, préfixé par le nom du projet Compose, conserve
les données dans Linux. Dans `docker_postgresql/compose.yaml`, sous
`services.postgres.environment`, `PGDATA` est explicitement fixé à
`/var/lib/postgresql/cluster`, sous le volume monté à `/var/lib/postgresql`.
Ce chemin identique fonctionne avant et après le changement de disposition de
l'image PostgreSQL 18 et évite d'initialiser silencieusement une nouvelle base
lors d'un changement majeur.

Créez vos éventuels scripts `.sql`, `.sql.gz` et `.sh` dans le dossier
**`docker_postgresql/docker/init/`**, avant le tout premier `start`.
Par exemple, placez votre schéma SQL dans
`docker_postgresql/docker/init/01-schema.sql` et vos données initiales dans
`docker_postgresql/docker/init/02-data.sql`. Ces fichiers sont exécutés
dans l'ordre de leur nom, **uniquement lors de la création d'un cluster vide**.
Dans votre éditeur, enregistrez les scripts shell avec des fins de ligne LF.
Une erreur peut laisser une initialisation partielle : corrigez-la explicitement ;
les scripts ne reprennent pas tout seuls.
Pour faire évoluer une base existante, utilisez des migrations.

`stop`, la recréation du conteneur et les mises à jour d'image conservent le volume.
**`docker compose down -v` supprime définitivement ses données.** Aucune commande
de remise à zéro automatique n'est fournie.

## Sauvegarde et restauration

Avec le service PostgreSQL démarré, exécutez ces commandes dans le terminal
ouvert à la racine de `docker_postgresql` :

```powershell
.\dev.ps1 backup
# Remplacez DATE-IDENTIFIANT.dump par le nom exact affiche par backup.
.\dev.ps1 restore backups/DATE-IDENTIFIANT.dump app_restored
```

Les archives sont écrites dans **`docker_postgresql/backups/`**. La commande
affiche le chemin complet du fichier créé ; vous pouvez aussi passer ce chemin
à `restore`, entouré de guillemets s'il contient des espaces. `app_restored` est
le nom de la nouvelle base à créer, pas un fichier : adaptez ce dernier argument
de la commande si vous souhaitez un autre nom. La restauration ne change pas
`POSTGRES_DB` dans `docker_postgresql/.env` ni la connexion de votre application.

Pour examiner la base restaurée, lancez `.\dev.ps1 psql`, puis saisissez
`\connect app_restored` dans la console SQL. Si elle devient votre base de
travail, remplacez la ligne `POSTGRES_DB` par `POSTGRES_DB=app_restored` dans
`docker_postgresql/.env`, puis lancez `.\dev.ps1 start` et `.\dev.ps1 check`.
Les prochaines commandes `backup` cibleront ainsi cette base déjà créée.
Adaptez également le nom de la base dans les paramètres de connexion de vos
clients et de vos applications.

La sauvegarde utilise `pg_dump --format=custom` puis `docker compose cp` pour
préserver les octets, y compris sous Windows PowerShell 5.1. Les archives sont
datées, ont un identifiant unique et sont ignorées par Git. Conservez une copie
ailleurs : le dossier `backups` seul ne protège pas contre la perte du poste.

`restore` exige une **nouvelle base** : si elle existe déjà, la commande échoue
sans la remplacer. Le nom doit commencer par une lettre minuscule et ne contenir
que minuscules, chiffres et underscores (63 caractères maximum). L'import est
transactionnel ; en cas d'échec, la base nouvellement créée peut rester vide.
Les objets restaurés appartiennent au compte local ; propriétaires et privilèges
de l'archive ne sont pas restaurés. N'importez que des archives de confiance.

Cette sauvegarde contient une seule base, pas les rôles globaux, les autres bases
ni la configuration du serveur. Pour un cluster comportant plusieurs rôles ou
bases, prévoyez également `pg_dumpall --globals-only` et les sauvegardes de chaque
base, avec une procédure adaptée aux droits et extensions utilisés.

## Mises à jour et changement de version

Pour récupérer les correctifs de la branche choisie, depuis la racine de
`docker_postgresql` et avec la base démarrée pour la sauvegarde :

```powershell
.\dev.ps1 backup
.\dev.ps1 pull
.\dev.ps1 start
.\dev.ps1 check
```

Pour fixer un correctif de la même branche majeure, effectuez d'abord la
sauvegarde, puis ouvrez **`docker_postgresql/.env`**, remplacez la valeur de la
ligne `POSTGRES_VERSION` (par exemple `POSTGRES_VERSION=16.15`) et enregistrez
avant `pull`, `start` et `check`. Un démarrage ordinaire ne force pas un nouveau
téléchargement si l'image est déjà disponible localement.

**Passer de 16 à 17 ou 18 nécessite une migration.** Modifier uniquement `.env`
ne convertit pas le volume : PostgreSQL refusera un cluster incompatible.
Ne supprimez pas le volume pour contourner cette erreur.

Procédure locale recommandée :

1. Suspendez les écritures de votre application, puis lancez `.\dev.ps1 backup`
   depuis le dossier de l'ancien environnement. Conservez le chemin de l'archive.
2. Préparez un second exemplaire des fichiers du projet dans un autre dossier,
   par exemple `docker_postgresql_v18`, sans recopier le `.env` local. Ouvrez
   un terminal dans ce nouveau dossier et lancez `.\dev.ps1 init`.
3. Dans **`docker_postgresql_v18/.env`**, définissez la nouvelle version avec
   `POSTGRES_VERSION=18`, un port libre avec par exemple `POSTGRES_PORT=5433`,
   et un nom distinct avec `COMPOSE_PROJECT_NAME=cours-blog-db-v18` (retirez
   le `#` devant cette dernière ligne). Enregistrez, puis lancez `.\dev.ps1 start`
   depuis ce nouveau dossier : le nom distinct crée un volume indépendant.
4. Copiez l'archive de l'ancien dossier `backups/` vers
   `docker_postgresql_v18/backups/`, puis lancez depuis `docker_postgresql_v18`
   `.\dev.ps1 restore backups/DATE-IDENTIFIANT.dump app_restored`, en remplaçant
   le nom du fichier. Pour sélectionner la base restaurée et la cibler dans les
   prochaines sauvegardes, définissez `POSTGRES_DB=app_restored` dans
   `docker_postgresql_v18/.env`, puis lancez `.\dev.ps1 start` et `.\dev.ps1 check`
   depuis `docker_postgresql_v18`. Vérifiez les données et votre application sur cette base.
   Pour une application Docker, adaptez `networks.postgresql.name` dans son
   propre fichier Compose pour utiliser `cours-blog-db-v18_default`. Dans sa
   configuration de connexion, renseignez le nouveau mot de passe et la base
   `app_restored`, puis appliquez ces changements avec sa procédure habituelle.
   Pour un client Windows,
   modifiez le port, la base et les identifiants dans ses paramètres de connexion.
5. Conservez l'ancien environnement et sa sauvegarde jusqu'à validation complète.

Les migrations importantes peuvent nécessiter `pg_upgrade` ou une procédure
personnalisée. La compatibilité applicative et celle des extensions restent à vérifier.

## Plusieurs projets

Dans le fichier `.env` à la racine de `docker_postgresql`, créé par
`.\dev.ps1 init`, choisissez un `COMPOSE_PROJECT_NAME` et un `POSTGRES_PORT`
distincts pour chaque projet avant le premier démarrage avec `.\dev.ps1 start`.
Par exemple :

```dotenv
COMPOSE_PROJECT_NAME=cours-blog-db
POSTGRES_PORT=5433
```

La ligne `COMPOSE_PROJECT_NAME` est présente en commentaire dans le modèle :
retirez le `#` devant cette ligne et remplacez sa valeur. Modifiez également la
valeur de la ligne `POSTGRES_PORT` existante.

Changer le nom après l'installation désigne un autre volume ; cela ne déplace
pas les données existantes. Aucun nom de conteneur ni réseau global n'est imposé.

## Vérification et dépannage

```powershell
docker compose config --quiet
.\tests\integration.Tests.ps1
.\tests\integration.Tests.ps1 -Version 18
```

Les tests créent un projet Compose unique dans un dossier temporaire, utilisent
un port disponible attribué par Docker et vérifient l'initialisation, la connexion,
la persistance après recréation, la sauvegarde, la restauration et le refus
d'écraser une base existante. Ils suppriment uniquement leurs propres ressources.
Ils nécessitent Docker et peuvent télécharger les images. GitHub Actions exécute
la même suite sur les branches 16, 17 et 18.

- Port déjà utilisé : modifiez la ligne `POSTGRES_PORT` dans
  `docker_postgresql/.env`, enregistrez, puis lancez `.\dev.ps1 start` depuis
  `docker_postgresql`. Actualisez aussi le port dans vos clients Windows.
- Mauvais mot de passe après modification de `.env` : les identifiants du volume
  existant n'ont pas changé ; suivez la procédure de changement de mot de passe
  de la section « Configuration ».
- Service non sain : lancez `.\dev.ps1 logs` depuis `docker_postgresql` pour
  repérer notamment les erreurs de scripts d'init ou de version majeure incompatible.
- Image introuvable : vérifiez la ligne `POSTGRES_VERSION` dans
  `docker_postgresql/.env`. Elle contient uniquement le numéro, par exemple `16` ;
  `docker_postgresql/compose.yaml` ajoute automatiquement le suffixe `-bookworm`.
  Vérifiez que le tag résultant existe dans l'image officielle liée en référence.
- Docker inaccessible : démarrez Docker Desktop en mode Linux.

## Git et releases

Cette section concerne la personne qui maintient et distribue le dépôt ; les
étudiants n'ont pas besoin de publier un dépôt ni de créer une release pour
utiliser PostgreSQL.

Pour distribuer votre propre dépôt, initialisez Git depuis la racine de
`docker_postgresql` et créez votre dépôt distant. Aucun dépôt distant n'est
préconfiguré. Ne versionnez ni `.env` ni
les sauvegardes. Relisez les fichiers avant votre premier commit.

Pour remettre le projet aux étudiants, privilégiez une archive de sources
générée depuis le dépôt Git ou une release identifiée. Ne compressez pas
directement votre dossier de travail : il peut contenir `.env`, `backups/`,
`.idea/` ou `.vscode/`, qui sont locaux et exclus par `.gitignore`.
Le `.env` doit être créé par chaque étudiant avec `init` pour obtenir son propre
mot de passe. Conservez `.env.example`, les fichiers cachés du dépôt et `LICENSE`
dans les sources distribuées.

```powershell
git init
git branch -M main
git add .
git diff --cached --stat
git diff --cached
git commit -m "feat: ajouter un environnement PostgreSQL local"
```

Les commits suivent Conventional Commits : `feat`,
`fix`, `docs`, `test`, `ci`, `chore`, avec scope facultatif et `!` pour les ruptures.
Le workflow `docker_postgresql/.github/workflows/release.yml` publie une release
sur GitHub lors du push d'un tag stable
`vMAJEUR.MINEUR.CORRECTIF`. git-cliff produit ses notes et un `CHANGELOG.md` joint ;
les releases déjà existantes sont conservées. Les versions des actions sont fixées.
Les archives de sources ZIP et tar.gz sont fournies par GitHub. Pour adapter le
classement ou le rendu des notes de release, modifiez
`docker_postgresql/cliff.toml`. Le `CHANGELOG.md` est généré dans GitHub Actions
et joint à la release ; aucun fichier local à ce nom n'est à modifier.

## Références

- [Image officielle PostgreSQL : variables, volumes et scripts d'initialisation](https://hub.docker.com/_/postgres).
- [Documentation PostgreSQL : changement de version](https://www.postgresql.org/docs/current/upgrading.html).
- [Documentation PostgreSQL : pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html).

## Licence

Copyright © 2026 Nicolas Vauché. GNU General Public License version 3 uniquement
(`GPL-3.0-only`). Voir [LICENSE](LICENSE).
Les composants tiers conservent leurs licences respectives.
