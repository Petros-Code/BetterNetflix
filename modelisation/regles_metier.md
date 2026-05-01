# Règles métier — BetterNetflix

## Modèle général

Le schéma repose sur une table centrale `content` qui regroupe tous les types de contenus (film, série, épisode, live). Chaque type possède sa propre table spécialisée liée par une relation 1-1 via `content_id`.

---

## Tables et cardinalités

### content
- Contient **tous** les contenus de la plateforme.
- Le champ `type` est une enum : `film`, `serie`, `episode`, `live`.
- `release_date` ne peut pas être dans le futur (`CHECK release_date <= CURRENT_DATE`).
- `meta` (JSONB) stocke des données variables : langues disponibles, formats, sous-titres, etc.

### film
- Relation **1-1** avec `content` (`content_id` est à la fois PK et FK).
- `classification_age` : âge minimum requis pour visionner.
- `budget` : budget de production en USD.

### series
- Relation **1-1** avec `content`.
- `nb_seasons` : nombre de saisons, doit être ≥ 1.

### episode
- Relation **1-1** avec `content`.
- `series_id` est **NOT NULL** : un épisode est obligatoirement rattaché à une série.
- (`season`, `nb_episode`, `series_id`) doivent être uniques ensemble : pas de doublon d'épisode dans une série.

### livestream
- Relation **1-1** avec `content`.
- Pas de champ durée : un live n'a pas de durée prédéfinie.
- `date_live` : date et heure de diffusion prévue, **NOT NULL**.
- `creator_id` : créateur indépendant, référence `personne`.

### personne
- Table commune aux acteurs, réalisateurs et créateurs de live.
- Un même individu peut être acteur ET réalisateur.

### Tables de liaison (n-n)
| Table | Relation |
|---|---|
| `film_acteur` | un film ↔ plusieurs acteurs, un acteur ↔ plusieurs films |
| `serie_acteur` | une série ↔ plusieurs acteurs |
| `episode_acteur` | un épisode ↔ plusieurs acteurs |
| `film_realisateur` | un film ↔ plusieurs réalisateurs |

- Les PK sont composites (ex : `(film_id, acteur_id)`).

### plan
- `name` est unique (pas deux plans avec le même nom).
- `advantages` (JSONB) : options variables selon le plan (qualité, nombre de profils, fonctionnalités).
- Exemple : `{ "qualite": "UHD", "profils": 4, "features": ["offline", "kids_mode"] }`

### utilisateur
- `email` est **UNIQUE** et **NOT NULL**.
- `plan_id` est **NOT NULL** : tout utilisateur doit avoir un abonnement.
- `appliance_date` : date de souscription au plan actuel.

### tag
- Hiérarchie auto-référente : `parent_id` pointe vers `tag.id` (nullable pour les tags racine).
- Exemple : `Action` (racine) → `Action/SF`, `Action/Thriller`.

### content_tag
- Table de liaison **n-n** entre `content` et `tag`.
- PK composite : `(content_id, tag_id)`.

### historique_vue
- PK composite : `(user_id, content_id, date_vue)` — un utilisateur peut voir plusieurs fois le même contenu.
- `progression` : entier entre 0 et 100 (`CHECK progression BETWEEN 0 AND 100`).

### recommandation
- PK composite : `(user_id, content_id)` — une seule recommandation par contenu par utilisateur.
- `score_algorithme` : score flottant généré par l'algorithme de recommandation.
- `raison` (JSONB) : détail des critères ayant généré la recommandation.
- Exemple : `{ "basé_sur": "tags", "acteur_prefere": "Tom Hanks", "similarite": 0.87 }`

---

## Contraintes métier clés

| Règle | Implémentation |
|---|---|
| Un épisode doit être lié à une série | `series_id NOT NULL` + FK vers `series` |
| Un live n'a pas de durée | Pas de champ `duree` dans `livestream` |
| La date de sortie ne peut pas être dans le futur | `CHECK (release_date <= CURRENT_DATE)` |
| La progression est entre 0 et 100 | `CHECK (progression BETWEEN 0 AND 100)` |
| Un utilisateur a toujours un abonnement | `plan_id NOT NULL` |
| Pas deux épisodes identiques dans une série | `UNIQUE (series_id, season, nb_episode)` |
| Email utilisateur unique | `UNIQUE (email)` |
| Nom de plan unique | `UNIQUE (name)` dans `plan` |
