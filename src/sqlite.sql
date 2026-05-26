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
    id_famille_metier TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL,
    description TEXT
);

CREATE TABLE statut_metier (
    id_statut_metier TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL
);

CREATE TABLE referentiel_competence (
    id_referentiel_competence TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL,
    type_referentiel TEXT NOT NULL,
    type_referentiel_detaille TEXT NOT NULL
);

CREATE TABLE groupe_competence (
    id_groupe_competence TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL,
    type_groupe TEXT
);

CREATE TABLE categorie_detention (
    id_categorie_detention TEXT PRIMARY KEY NOT NULL,
    libelle TEXT NOT NULL,
    gamme_detention TEXT NOT NULL
);

CREATE TABLE metier (
    code_metier TEXT PRIMARY KEY NOT NULL,
    id_neobrain_metier INTEGER NOT NULL,
    metier_collaborateur TEXT NOT NULL,
    id_famille_metier TEXT NOT NULL,
    id_statut_metier TEXT NOT NULL,
    metier_actif INTEGER NOT NULL, -- en sqlite, le type BOOLEAN peut etre représenté par un 0/1
    FOREIGN KEY (id_famille_metier) REFERENCES famille_metier(id_famille_metier),
    FOREIGN KEY (id_statut_metier) REFERENCES statut_metier(id_statut_metier)
);

CREATE INDEX idx_metier_famille ON metier(id_famille_metier);
CREATE INDEX idx_metier_statut ON metier(id_statut_metier);

CREATE TABLE competence (
    code_competence TEXT PRIMARY KEY NOT NULL,
    id_neobrain_competence INTEGER NOT NULL,
    id_groupe_competence TEXT NOT NULL,
    id_referentiel_competence TEXT NOT NULL,
    FOREIGN KEY (id_groupe_competence) REFERENCES groupe_competence(id_groupe_competence),
    FOREIGN KEY (id_referentiel_competence) REFERENCES referentiel_competence(id_referentiel_competence)
);

CREATE INDEX idx_competence_id_groupe ON competence(id_groupe_competence);
CREATE INDEX idx_competence_id_referentiel ON competence(id_referentiel_competence);

CREATE TABLE competence_utilisateur (
    code_competence TEXT PRIMARY KEY NOT NULL,
    nom_competence TEXT NOT NULL,
    id_categorie_detention TEXT NOT NULL,
    date_mise_a_jour TEXT NOT NULL, -- En sqlite, le TIMESTAMP est un TEXT en ISO8601
    FOREIGN KEY (code_competence) REFERENCES competence(code_competence),
    FOREIGN KEY (id_categorie_detention) REFERENCES categorie_detention(id_categorie_detention)
);

CREATE INDEX idx_competence_utilisateur_competence ON competence_utilisateur(code_competence);
CREATE INDEX idx_competence_utilisateur_categorie ON competence_utilisateur(id_categorie_detention);

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

CREATE TABLE about (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

.import --csv --skip 1 data/output/famille_metier.csv famille_metier
.import --csv --skip 1 data/output/statut_metier.csv statut_metier
.import --csv --skip 1 data/output/referentiel_competence.csv referentiel_competence
.import --csv --skip 1 data/output/groupe_competence.csv groupe_competence
.import --csv --skip 1 data/output/categorie_detention.csv categorie_detention
.import --csv --skip 1 data/output/metier.csv metier
.import --csv --skip 1 data/output/competence.csv competence
.import --csv --skip 1 data/output/competence_utilisateur.csv competence_utilisateur
.import --csv --skip 1 data/output/niveau_description_competence.csv niveau_description_competence
.import --csv --skip 1 data/output/metier_competence.csv metier_competence
.import --csv --skip 1 data/output/about.csv about


CREATE VIEW vw_lister_competences_metier AS
SELECT
    m.code_metier,
    m.metier_collaborateur,
    c.code_competence,
    mc.nom_competence,
    (SELECT g.libelle FROM groupe_competence g WHERE c.id_groupe_competence = g.id_groupe_competence) AS groupe_competence,
    (SELECT r.libelle FROM referentiel_competence r WHERE c.id_referentiel_competence = r.id_referentiel_competence) AS referentiel_competence
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
JOIN groupe_competence g ON c.id_groupe_competence = g.id_groupe_competence
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
LEFT JOIN groupe_competence gc ON c.id_groupe_competence = gc.id_groupe_competence
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
JOIN famille_metier fm ON m.id_famille_metier = fm.id_famille_metier
JOIN statut_metier stm ON m.id_statut_metier = stm.id_statut_metier
WHERE NOT EXISTS (
    SELECT 1 FROM metier_competence mc WHERE mc.code_metier = m.code_metier
);
