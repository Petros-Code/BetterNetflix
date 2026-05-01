# 🐳🎬 TP – Modélisation & PostgreSQL dans Docker : Plateforme BetterNetflix

## 🎯 Objectifs pédagogiques

Ce TP a pour but de vous faire pratiquer :

- La modélisation d’une base de données complexe

- Le déploiement d’un PostgreSQL dans Docker

- L’écriture de scripts SQL (DDL + DML)

- La création de contraintes, index, tables de liaison, clés étrangères

- L’utilisation de JSONB pour les données semi-structurées

- La réalisation de requêtes SQL avancées (CTE, filtres JSONB, agrégations)

## 📦 Contexte du projet : Plateforme BetterNetflix

Vous travaillez comme équipe Data pour BetterNetflix, une plateforme de streaming internationale.

La plateforme propose :

- **Films**

- **Séries**

- **Épisodes de séries**

- **Live streams** créés par des créateurs indépendants

- Des utilisateurs aux abonnements **variés**

- Des tags **hiérarchiques** (genres et sous-genres)

- Des recommandations **personnalisées**

- Un historique de visionnage détaillé

=> Ce qu'on va faire nous : concevoir et mettre en place toute la base de données.

## 🧱 Étape 1 — Mise en place de l’environnement Docker

Créez un fichier `docker-compose.yml` :

```yml
services:
  postgres:
    image: postgres:16
    container_name: betternetflix-db
    environment:
      POSTGRES_PASSWORD: bettersecret
      POSTGRES_USER: betteruser
      POSTGRES_DB: betternetflix
    ports:
      - "5432:5432"
    volumes:
      - ./db-data:/var/lib/postgresql/data
      - ./init:/docker-entrypoint-initdb.d

```

Le dossier init/ contiendra vos fichiers SQL de création de schéma.
Le script principal devra s’appeler 01_schema.sql.

Démarrez l’environnement avec la commande 

```bash 
docker exec -it betternetflix-db psql -U betteruser -d betternetflix
```

## 🧠 Étape 2 — Modélisation (MLD / UML)

Vous devez formaliser un schéma relationnel complet pour BetterNetflix.
Ce schéma doit être remis sous forme :

- de MPD ou diagramme UML

accompagné d’une description des règles métier

avec toutes les cardinalités

et toutes les contraintes

Le modèle doit inclure (obligatoire) :

### 🎬 Table content

Table centrale listant tous les contenus disponibles.

Champs obligatoires :

- `id` (PK)

- `type` (film, serie, episode, live)

- `title`

- `description`

- `contry_production`

- `release_date`

- `meta` (JSONB) : métadonnées variables (langues, formats, sous-titres…)

### 🎞 Films

```
film (
  content_id PK FK → content,
  classification_age,
  budget
)
```

### 📺 Séries

```
series (
  content_id PK FK → content,
  nb_seasons
)
```

### 🎬 Episodes

```
episode (
  content_id PK FK → content,
  series_id FK → serie,
  season,
  nb_episode
)
```

### 🔴 Live streams

```
livestream (
  content_id PK FK → content,
  date_live,
  creator_id FK → createur_independant
)
```

## 🎭 Personnes & créateurs

### Table `personne`

- id
- name
- birth_date
- biography

### Acteurs & réalisateurs (relations n-n avec films/séries/épisodes)

Tables de liaison à prévoir :

film_acteur (film_id, acteur_id)

serie_acteur (serie_id, acteur_id)

episode_acteur (episode_id, acteur_id)

film_realisateur (film_id, realisateur_id)

## 👥 Utilisateurs et abonnement

### Table user

- id
- email (unique)
- country
- plan_id
- appliance_date

### Table plan

- id
- name (Basic, Premium, Creator+, etc.)
- price
- advantages (JSONB) → options variables selon le plan

```json
{
  "qualite": "UHD",
  "profils": 4,
  "features": ["offline", "kids_mode"]
}
```

## 🧩 Tags hiérarchiques

### Table tag

- id
- parent_id (FK vers tag.id)
- nom


### Table content_tag

- content_id
- tag_id


## 📈 Historique & recommandations

### Table historique_vue

- user_id
- content_id
- date_vue
- progression (0–100)

### Table recommandation

- user_id
- content_id
- score_algorithme
- raison (JSONB) — contenu variable selon les règles de l’algo


---

## ✍️ Etape 3 : Implémentation SQL

Vous devez produire un fichier init/01_schema.sql incluant :

- Création de toutes les tables

- Contraintes (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, NOT NULL)

- Contraintes métier (exemples) :

  - un épisode doit obligatoirement être lié à une série
  - un live stream ne doit pas avoir de durée
  - date_sortie ne peut pas être dans le futur

- Index pertinents
- Index GIN pour les champs JSONB
- Triggers si nécessaire
(ex : mise à jour de la barre de progression automatique lorsqu'une série est visionnée)

## 🧪 Etape 4 : Jeu de données

Vous devez produire un fichier `init/02_data.sql` pour insérer des données d’exemple :

- Minimum 5 films
- Minimum 2 séries + au moins 6 épisodes chacun
- Minimum 2 live streams programmés
- Minimum 10 acteurs et 5 réalisateurs
- Au moins 15 tags hiérarchiques
- Au moins 20 utilisateurs
- Un historique varié
- Quelques recommandations pour 4–5 utilisateurs

## 🔍 Étape 5 — Requêtes SQL à produire

### Requêtes obligatoires

- Top 10 des contenus les plus vus par pays

- Liste des séries dont la moyenne de progression des utilisateurs > 80 %

- Affichage de la hiérarchie complète des tags (CTE récursif)

- Recommander à un utilisateur les contenus d’un acteur qu’il regarde le plus

- Films du même réalisateur que le dernier film vu par un utilisateur

- Abonnements possédant l’option “UHD” (requête JSONB)

### Bonus

Vue matérialisée “contenus tendances”

Fonction SQL retournant les 5 contenus les plus similaires (basé sur les tags)

## 🛡️ Étape 6 — Politique de sauvegarde PostgreSQL sous Linux

Dans cette étape, vous devez mettre en place une stratégie de sauvegarde complète et automatisée de la base de données BetterNetflix, comme cela doit être fait sur un serveur Linux en production.


### 📌 1. Script de sauvegarde : `backup.sh`

Créer un script shell qui :

1. Génère un fichier de sauvegarde logique avec pg_dump
2. Inclut la date et l’heure dans le nom du fichier
3. Gère les erreurs avec des messages clairs
4. Stocke le résultat dans backup/archive/
5. Logue chaque action dans backup/logs/backup.log

### 📌 2. Script de rotation : `retention.sh`

Objectif : ne conserver que les 7 derniers jours de sauvegarde.

### 📌 3. Automatisation via CRON 

Vous devez :

- Programmer les sauvegardes chaque nuit à 2h

- Programmer la rotation des sauvegardes chaque dimanche à 3h

### 📌 4. Documenter votre stratégie de sauvegarde

Vous devez produire un fichier backup/README.md contenant :

- Les objectifs de la politique de sauvegarde

- Le type de sauvegarde utilisé (pg_dump = logique)

- Le planning des sauvegardes

- La gestion de la rétention

- Les limites du système

- Comment restaurer la base depuis un fichier .sql

Exemple de commande de restauration :

```bash
psql -U archi -d betternetflix < betternetflix_20250110_020000.sql

```

### Livrables attendus 

```
/init
├── 01_schema.sql
├── 02_data.sql
/backup
├── backup.sh
├── retention.sh
├── logs/
├── archive/
/modelisation
├── diagramme.png
├── regles_metier.md
/requetes
├── requetes.sql
README.md
```

