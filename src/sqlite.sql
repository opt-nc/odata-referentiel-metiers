DROP VIEW IF EXISTS vw_metiers_orphelins;
DROP VIEW IF EXISTS vw_competences_architecte_logiciel;
DROP VIEW IF EXISTS vw_competences_orphelines;
DROP VIEW IF EXISTS vw_compter_competences_par_metier;
DROP VIEW IF EXISTS vw_lister_competences_metier;

DROP TABLE IF EXISTS about;
DROP TABLE IF EXISTS metier_competence;
DROP TABLE IF EXISTS niveau_description_competence;
DROP TABLE IF EXISTS competence_utilisateur;
DROP TABLE IF EXISTS competence;
DROP TABLE IF EXISTS categorie_detention;
DROP TABLE IF EXISTS groupe_competence;
DROP TABLE IF EXISTS referentiel_competence;
DROP TABLE IF EXISTS metier;
DROP TABLE IF EXISTS statut_metier;
DROP TABLE IF EXISTS famille_metier;

CREATE TABLE famille_metier (
    famille_metier_id TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL,
    description TEXT
);

CREATE TABLE statut_metier (
    statut_metier_id TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL
);

CREATE TABLE referentiel_competence (
    referentiel_competence_id TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL,
    type_referentiel TEXT NOT NULL,
    type_referentiel_detaille TEXT NOT NULL
);

CREATE TABLE groupe_competence (
    groupe_competence_id TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL,
    type_groupe TEXT
);

CREATE TABLE categorie_detention (
    categorie_detention_id TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL,
    gamme_detention TEXT NOT NULL
);

CREATE TABLE metier (
    code_metier TEXT PRIMARY KEY NOT NULL,
    neobrain_metier_id INTEGER NOT NULL,
    metier_collaborateur TEXT NOT NULL,
    famille_metier_id TEXT NOT NULL,
    statut_metier_id TEXT NOT NULL,
    metier_actif INTEGER NOT NULL, -- en sqlite, le type BOOLEAN peut etre représenté par un 0/1
    FOREIGN KEY (famille_metier_id) REFERENCES famille_metier(famille_metier_id),
    FOREIGN KEY (statut_metier_id) REFERENCES statut_metier(statut_metier_id)
);

CREATE INDEX idx_metier_famille ON metier(famille_metier_id);
CREATE INDEX idx_metier_statut ON metier(statut_metier_id);

CREATE TABLE competence (
    code_competence TEXT PRIMARY KEY NOT NULL,
    neobrain_competence_id INTEGER NOT NULL,
    groupe_competence_id TEXT NOT NULL,
    referentiel_competence_id TEXT NOT NULL,
    FOREIGN KEY (groupe_competence_id) REFERENCES groupe_competence(groupe_competence_id),
    FOREIGN KEY (referentiel_competence_id) REFERENCES referentiel_competence(referentiel_competence_id)
);

CREATE INDEX idx_competence_groupe_id ON competence(groupe_competence_id);
CREATE INDEX idx_competence_referentiel_id ON competence(referentiel_competence_id);

CREATE TABLE competence_utilisateur (
    code_competence TEXT PRIMARY KEY NOT NULL,
    nom_competence TEXT NOT NULL,
    categorie_detention_id TEXT NOT NULL,
    date_mise_a_jour TEXT NOT NULL, -- En sqlite, le TIMESTAMP est un TEXT en ISO8601
    FOREIGN KEY (code_competence) REFERENCES competence(code_competence),
    FOREIGN KEY (categorie_detention_id) REFERENCES categorie_detention(categorie_detention_id)
);

CREATE INDEX idx_competence_utilisateur_competence ON competence_utilisateur(code_competence);
CREATE INDEX idx_competence_utilisateur_categorie ON competence_utilisateur(categorie_detention_id);

CREATE TABLE niveau_description_competence (
    code_competence TEXT NOT NULL,
    niveau INTEGER NOT NULL,
    description TEXT NOT NULL,
    PRIMARY KEY (code_competence, niveau),
    FOREIGN KEY (code_competence) REFERENCES competence_utilisateur(code_competence)
);

CREATE INDEX idx_niveau_description_comp_utilisateur ON niveau_description_competence(code_competence);

CREATE TABLE metier_competence (
    code_metier TEXT NOT NULL,
    code_competence TEXT NOT NULL,
    nom_competence TEXT NOT NULL,
    poids REAL,
    niveau_requis REAL,
    est_actif INTEGER NOT NULL,
    date_creation TEXT NOT NULL,
    date_mise_a_jour TEXT NOT NULL,
    PRIMARY KEY (code_metier, code_competence, nom_competence),
    FOREIGN KEY (code_metier) REFERENCES metier(code_metier),
    FOREIGN KEY (code_competence) REFERENCES competence(code_competence)
);

CREATE INDEX idx_metier_competence_competence ON metier_competence(code_competence);
CREATE INDEX idx_metier_competence_metier ON metier_competence(code_metier);

CREATE TABLE famille_metier_couleur (
    famille_metier_id TEXT PRIMARY KEY NOT NULL,
    couleur TEXT NOT NULL,
    FOREIGN KEY (famille_metier_id) REFERENCES famille_metier(famille_metier_id)
);

CREATE INDEX idx_famille_metier_couleur_famille ON famille_metier_couleur(famille_metier_id);

CREATE TABLE about (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

.import --csv --skip 1 data/output/csv/famille_metier.csv famille_metier
.import --csv --skip 1 data/output/csv/statut_metier.csv statut_metier
.import --csv --skip 1 data/output/csv/referentiel_competence.csv referentiel_competence
.import --csv --skip 1 data/output/csv/groupe_competence.csv groupe_competence
.import --csv --skip 1 data/output/csv/categorie_detention.csv categorie_detention
.import --csv --skip 1 data/output/csv/metier.csv metier
.import --csv --skip 1 data/output/csv/competence.csv competence
.import --csv --skip 1 data/output/csv/competence_utilisateur.csv competence_utilisateur
.import --csv --skip 1 data/output/csv/niveau_description_competence.csv niveau_description_competence
.import --csv --skip 1 data/output/csv/metier_competence.csv metier_competence
.import --csv --skip 1 data/output/csv/famille_metier_couleur.csv famille_metier_couleur
.import --csv --skip 1 data/output/csv/about.csv about


CREATE VIEW vw_lister_competences_metier AS
SELECT
    m.code_metier,
    m.metier_collaborateur,
    c.code_competence,
    mc.nom_competence,
    (SELECT g.libelle FROM groupe_competence g WHERE c.groupe_competence_id = g.groupe_competence_id) AS groupe_competence,
    (SELECT r.libelle FROM referentiel_competence r WHERE c.referentiel_competence_id = r.referentiel_competence_id) AS referentiel_competence
FROM metier m
JOIN metier_competence mc ON m.code_metier = mc.code_metier
JOIN competence c ON mc.code_competence = c.code_competence
ORDER BY m.code_metier;

CREATE VIEW vw_compter_competences_par_metier AS
SELECT
    m.code_metier,
    m.metier_collaborateur,
    (SELECT COUNT(1) FROM metier_competence mc WHERE mc.code_metier = m.code_metier) AS nb_competences,
    (SELECT COUNT(1) FROM metier_competence mc WHERE mc.code_metier = m.code_metier AND mc.est_actif = 1) AS nb_competences_actives,
    (SELECT AVG(mc.niveau_requis) FROM metier_competence mc WHERE mc.code_metier = m.code_metier) AS niveau_moyen_requis,
    (SELECT SUM(mc.poids) FROM metier_competence mc WHERE mc.code_metier = m.code_metier) AS poids_total
FROM metier m
ORDER BY nb_competences;

CREATE VIEW vw_competences_orphelines AS
SELECT
    c.code_competence,
    cu.nom_competence,
    g.libelle AS groupe_competence
FROM competence c
JOIN competence_utilisateur cu ON c.code_competence = cu.code_competence
JOIN groupe_competence g ON c.groupe_competence_id = g.groupe_competence_id
WHERE NOT EXISTS (
    SELECT 1 FROM metier_competence mc WHERE mc.code_competence = c.code_competence
);

CREATE VIEW vw_competences_architecte_logiciel AS
SELECT
    gc.libelle AS groupe_competence,
    m.metier_collaborateur,
    cu.code_competence,
    mc.nom_competence AS nom_competence_metier,
    mc.niveau_requis,
    ndc.description AS description_niveau_requis
FROM metier m
JOIN metier_competence mc ON m.code_metier = mc.code_metier
JOIN competence_utilisateur cu ON mc.code_competence = cu.code_competence
JOIN competence c ON mc.code_competence = c.code_competence
LEFT JOIN groupe_competence gc ON c.groupe_competence_id = gc.groupe_competence_id
LEFT JOIN niveau_description_competence ndc ON cu.code_competence = ndc.code_competence AND ndc.niveau = CAST(mc.niveau_requis AS INTEGER)
WHERE lower(m.metier_collaborateur) = 'architecte logiciel';

CREATE VIEW vw_metiers_orphelins AS
SELECT
    m.code_metier,
    m.metier_collaborateur,
    fm.libelle AS famille_metier,
    stm.libelle AS statut_metier,
    m.metier_actif
FROM metier m
JOIN famille_metier fm ON m.famille_metier_id = fm.famille_metier_id
JOIN statut_metier stm ON m.statut_metier_id = stm.statut_metier_id
WHERE NOT EXISTS (
    SELECT 1 FROM metier_competence mc WHERE mc.code_metier = m.code_metier
);
