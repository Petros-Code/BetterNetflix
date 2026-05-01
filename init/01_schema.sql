-- ============================================================
-- BetterNetflix — Schema DDL
-- ============================================================

-- Types enum
CREATE TYPE content_type AS ENUM ('film', 'serie', 'episode', 'live');

-- ============================================================
-- PLANS D'ABONNEMENT
-- ============================================================
CREATE TABLE plan (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL UNIQUE,
    price   NUMERIC(8,2) NOT NULL CHECK (price >= 0),
    advantages JSONB
);

-- ============================================================
-- UTILISATEURS
-- ============================================================
CREATE TABLE utilisateur (
    id             SERIAL PRIMARY KEY,
    email          VARCHAR(255) NOT NULL UNIQUE,
    country        VARCHAR(100),
    plan_id        INT NOT NULL REFERENCES plan(id),
    appliance_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ============================================================
-- PERSONNES (acteurs, réalisateurs, créateurs)
-- ============================================================
CREATE TABLE personne (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    birth_date DATE,
    biography  TEXT
);

-- ============================================================
-- TABLE CENTRALE : CONTENT
-- ============================================================
CREATE TABLE content (
    id                 SERIAL PRIMARY KEY,
    type               content_type NOT NULL,
    title              VARCHAR(500) NOT NULL,
    description        TEXT,
    country_production VARCHAR(100),
    release_date       DATE CHECK (release_date <= CURRENT_DATE),
    meta               JSONB
);

-- ============================================================
-- FILMS
-- ============================================================
CREATE TABLE film (
    content_id        INT PRIMARY KEY REFERENCES content(id) ON DELETE CASCADE,
    classification_age INT CHECK (classification_age >= 0),
    budget            NUMERIC(15,2) CHECK (budget >= 0)
);

-- ============================================================
-- SERIES
-- ============================================================
CREATE TABLE series (
    content_id INT PRIMARY KEY REFERENCES content(id) ON DELETE CASCADE,
    nb_seasons INT NOT NULL DEFAULT 1 CHECK (nb_seasons >= 1)
);

-- ============================================================
-- EPISODES
-- ============================================================
CREATE TABLE episode (
    content_id INT PRIMARY KEY REFERENCES content(id) ON DELETE CASCADE,
    series_id  INT NOT NULL REFERENCES series(content_id) ON DELETE CASCADE,
    season     INT NOT NULL CHECK (season >= 1),
    nb_episode INT NOT NULL CHECK (nb_episode >= 1),
    UNIQUE (series_id, season, nb_episode)
);

-- ============================================================
-- LIVE STREAMS (pas de durée)
-- ============================================================
CREATE TABLE livestream (
    content_id INT PRIMARY KEY REFERENCES content(id) ON DELETE CASCADE,
    date_live  TIMESTAMP NOT NULL,
    creator_id INT REFERENCES personne(id) ON DELETE SET NULL
);

-- ============================================================
-- TABLES DE LIAISON : ACTEURS & REALISATEURS
-- ============================================================
CREATE TABLE film_acteur (
    film_id   INT NOT NULL REFERENCES film(content_id) ON DELETE CASCADE,
    acteur_id INT NOT NULL REFERENCES personne(id) ON DELETE CASCADE,
    PRIMARY KEY (film_id, acteur_id)
);

CREATE TABLE serie_acteur (
    serie_id  INT NOT NULL REFERENCES series(content_id) ON DELETE CASCADE,
    acteur_id INT NOT NULL REFERENCES personne(id) ON DELETE CASCADE,
    PRIMARY KEY (serie_id, acteur_id)
);

CREATE TABLE episode_acteur (
    episode_id INT NOT NULL REFERENCES episode(content_id) ON DELETE CASCADE,
    acteur_id  INT NOT NULL REFERENCES personne(id) ON DELETE CASCADE,
    PRIMARY KEY (episode_id, acteur_id)
);

CREATE TABLE film_realisateur (
    film_id       INT NOT NULL REFERENCES film(content_id) ON DELETE CASCADE,
    realisateur_id INT NOT NULL REFERENCES personne(id) ON DELETE CASCADE,
    PRIMARY KEY (film_id, realisateur_id)
);

-- ============================================================
-- TAGS HIERARCHIQUES
-- ============================================================
CREATE TABLE tag (
    id        SERIAL PRIMARY KEY,
    parent_id INT REFERENCES tag(id) ON DELETE SET NULL,
    nom       VARCHAR(100) NOT NULL
);

CREATE TABLE content_tag (
    content_id INT NOT NULL REFERENCES content(id) ON DELETE CASCADE,
    tag_id     INT NOT NULL REFERENCES tag(id) ON DELETE CASCADE,
    PRIMARY KEY (content_id, tag_id)
);

-- ============================================================
-- HISTORIQUE DE VISIONNAGE
-- ============================================================
CREATE TABLE historique_vue (
    user_id     INT NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
    content_id  INT NOT NULL REFERENCES content(id) ON DELETE CASCADE,
    date_vue    TIMESTAMP NOT NULL DEFAULT NOW(),
    progression INT NOT NULL DEFAULT 0 CHECK (progression BETWEEN 0 AND 100),
    PRIMARY KEY (user_id, content_id, date_vue)
);

-- ============================================================
-- RECOMMANDATIONS
-- ============================================================
CREATE TABLE recommandation (
    user_id           INT NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
    content_id        INT NOT NULL REFERENCES content(id) ON DELETE CASCADE,
    score_algorithme  FLOAT CHECK (score_algorithme BETWEEN 0 AND 1),
    raison            JSONB,
    PRIMARY KEY (user_id, content_id)
);

-- ============================================================
-- INDEX
-- ============================================================
-- Recherche par type de contenu
CREATE INDEX idx_content_type ON content(type);

-- Recherche par titre
CREATE INDEX idx_content_title ON content(title);

-- Épisodes par série
CREATE INDEX idx_episode_series ON episode(series_id);

-- Historique par utilisateur
CREATE INDEX idx_historique_user ON historique_vue(user_id);

-- Historique par contenu
CREATE INDEX idx_historique_content ON historique_vue(content_id);

-- Recommandations par utilisateur
CREATE INDEX idx_recommandation_user ON recommandation(user_id);

-- Index GIN pour les champs JSONB
CREATE INDEX idx_content_meta          ON content      USING GIN (meta);
CREATE INDEX idx_plan_advantages       ON plan         USING GIN (advantages);
CREATE INDEX idx_recommandation_raison ON recommandation USING GIN (raison);

-- ============================================================
-- TRIGGER : mise à jour auto de nb_seasons sur episode insert
-- ============================================================
CREATE OR REPLACE FUNCTION update_nb_seasons()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE series
    SET nb_seasons = (
        SELECT MAX(season)
        FROM episode
        WHERE series_id = NEW.series_id
    )
    WHERE content_id = NEW.series_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_nb_seasons
AFTER INSERT OR UPDATE ON episode
FOR EACH ROW EXECUTE FUNCTION update_nb_seasons();
