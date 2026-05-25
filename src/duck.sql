DROP MACRO IF EXISTS formatter;

-- Cette macro permet essentiellement de uniformiser le format des clés primaires et étrangères à partir des libellés.
-- Exemple : formatter(Vente & relation client) devient "vente_relation_client"
CREATE MACRO formatter(str) AS (
    TRIM(
        BOTH '_' FROM
        REGEXP_REPLACE(
            LOWER(
                TRANSLATE(
                    COALESCE(str, ''),    -- renvoie une chaîne vide, si le libelle est vide
                    'éèêëàâäîïôöùûüç',    -- On retire les accents.
                    'eeeeaaaiioouuuc'
                )
            ),
            '[^a-z0-9]+',                 -- Tout ce qui n'est ni une lettre alphabetique, ni un chiffre devient un '_'
            '_',
            'g'
        )
    )
);

DROP TABLE IF EXISTS metier_competence;
DROP TABLE IF EXISTS niveau_description_competence;
DROP TABLE IF EXISTS competence_utilisateur;
DROP TABLE IF EXISTS competence_attribut;
DROP TABLE IF EXISTS metier;
DROP TABLE IF EXISTS famille_metier;
DROP TABLE IF EXISTS competence;

DROP TABLE IF EXISTS statut_metier;
DROP TABLE IF EXISTS referentiel_competence;
DROP TABLE IF EXISTS groupe_competence;
DROP TABLE IF EXISTS categorie_detention;

DROP TABLE IF EXISTS about;

DROP INDEX IF EXISTS idx_metier_famille;
DROP INDEX IF EXISTS idx_metier_statut;
DROP INDEX IF EXISTS idx_competence_groupe;
DROP INDEX IF EXISTS idx_competence_referentiel;
DROP INDEX IF EXISTS idx_competence_utilisateur_categorie;
DROP INDEX IF EXISTS idx_niveau_description_comp_utilisateur;
DROP INDEX IF EXISTS idx_metier_competence_competence;
DROP INDEX IF EXISTS idx_metier_competence_metier;

CREATE TEMP TABLE gem_metier AS
SELECT
    "Nom Client" AS nom_client,
    "Id Neobrain Métier" AS id_neobrain_metier,
    "Code Métier" AS code_metier,
    "Métier collaborateur" as nom_metier,
    "Famille métier" AS famille_metier,
    "Nombre de compétences du métier" AS nb_competence_metier,
    "Niveau de compétence moyen requis" AS niveau_competence_moyen_requis,
    "Métier actif? 0/1" AS metier_active_count,
    "Métier actif?" = 'True' AS metier_actif,
    "Statut du métier" AS statut_metier
FROM read_csv_auto('data/input/gem_metiers.csv');

CREATE TEMP TABLE gem_competence AS
SELECT
    "Nom Client" AS nom_client,
    "Id interne Neobrain Client" AS id_neobrain_client,
    "Id interne Neobrain Compétence" AS id_neobrain_competence,
    "Code de compétence" AS code_competence,
    "Nom de la compétence" AS nom_competence,
    "Référentiel de compétences" AS referentiel_competence,
    "Type de référentiel de compétences" AS type_referentiel_competence,
    "Type de référentiel de compétences détaillé" AS type_referentiel_competence_detaille,
    "Groupe de compétences" AS groupe_competence,
    "Type de groupe de compétences" AS type_groupe_competence,
    "Compétence mise à jour le" date_mise_a_jour,
    "Maîtrise moyenne de la compétence" AS maitrise_moyenne,
    "Motivation moyenne sur la compétence" AS motivation_moyenne,
    "Maîtrise moyenne de la compétence (note du manager)" AS maitrise_moyenne_note_manager,
    "Collaborateurs actifs possédant cette compétence" AS nb_collaborateurs_actifs,
    "Nombre de collaborateurs actifs à reskiller" AS nb_collaborateur_a_reskiller,
    "Nombre de métiers actifs ayant cette compétence" AS nb_metier_possedant_ce_metier,
    "Catégorie de détention de compétences" categorie_detention,
    "Gamme de détention dans les métiers de la compétence" AS gamme_detention,
    "Description Niveau 1 Compétence" AS description_niveau_1,
    "Description Niveau 2 Compétence" AS description_niveau_2,
    "Description Niveau 3 Compétence" AS description_niveau_3,
    "Description Niveau 4 Compétence" AS description_niveau_4,
FROM read_csv_auto('data/input/gem_competences.csv')
WHERE code_competence IS NOT NULL;

CREATE TEMP TABLE gem_metier_competence AS
SELECT
    "Id Neobrain Métier" AS id_neobrain_metier,
    "Code Métier" AS code_metier,
    "Métier collaborateur" as nom_metier,
    "Famille métier" AS famille_metier,
    "Nom de la compétence" AS nom_competence,
    "Référentiel de compétences" AS referentiel_competence,
    "Code de compétence" AS code_competence,
    "Id interne Neobrain Compétence" AS id_neobrain_competence,
    "Groupe de compétences" AS groupe_competence,
    "Poids de la compétence" AS poids,
    "Niveau requis pour le métier" niveau_requis,
    "Relation Métier-Compétence créée le" date_creation,
    "Relation Métier-Compétence mise à jour le" AS date_mise_a_jour,
    "Relation Métier-Compétence active?" = 'True' AS relation_metier_competence_active

FROM read_csv_auto('data/input/gem_metiers_competences.csv')
WHERE code_competence IS NOT NULL;

CREATE TABLE famille_metier (
    id_famille_metier VARCHAR PRIMARY KEY NOT NULL,
    libelle VARCHAR NOT NULL,
    description VARCHAR,
);

INSERT INTO famille_metier
SELECT DISTINCT
    formatter(famille_metier) AS id_famille_metier,
    famille_metier AS libelle,
    NULL AS description,
FROM gem_metier
WHERE formatter(famille_metier) IS NOT NULL;

COMMENT ON TABLE famille_metier IS 'Référentiel des familles de métiers de l''entreprise';
COMMENT ON COLUMN famille_metier.id_famille_metier IS 'Identifiant unique de la famille (généré par formatter)';
COMMENT ON COLUMN famille_metier.libelle IS 'Libellé complet de la famille de métiers';
COMMENT ON COLUMN famille_metier.description IS 'Description optionnelle de la famille';

CREATE TABLE statut_metier (
    id_statut_metier VARCHAR PRIMARY KEY,
    libelle VARCHAR NOT NULL
);

INSERT INTO statut_metier
SELECT DISTINCT
    UPPER(formatter(statut)) AS id_statut_metier,
    statut AS libelle
FROM (
    SELECT DISTINCT statut_metier AS statut
    FROM gem_metier
) WHERE statut IS NOT NULL;

COMMENT ON TABLE statut_metier IS 'Référentiel des statuts possibles d un métier (ex: Publié)';
COMMENT ON COLUMN statut_metier.id_statut_metier IS 'Identifiant unique du statut en majuscules (généré par formatter)';
COMMENT ON COLUMN statut_metier.libelle IS 'Nom du statut du métier';

CREATE TABLE metier (
    code_metier VARCHAR PRIMARY KEY NOT NULL,
    id_neobrain_metier INTEGER NOT NULL,
    metier_collaborateur VARCHAR NOT NULL,
    id_famille_metier VARCHAR NOT NULL,
    id_statut_metier VARCHAR NOT NULL,
    metier_actif BOOLEAN NOT NULL,
    CONSTRAINT fk_metier_famille
        FOREIGN KEY (id_famille_metier) REFERENCES famille_metier(id_famille_metier),
    CONSTRAINT fk_metier_statut
        FOREIGN KEY (id_statut_metier) REFERENCES statut_metier(id_statut_metier)
);

CREATE INDEX idx_metier_famille ON metier(id_famille_metier);
CREATE INDEX idx_metier_statut ON metier(id_statut_metier);

INSERT INTO metier
SELECT DISTINCT
    gmc.code_metier AS code_metier,
    gmc.id_neobrain_metier AS id_neobrain_metier,
    gmc.nom_metier AS metier_collaborateur,
    formatter(gmc.famille_metier) AS id_famille_metier,
    UPPER(formatter(gm.statut_metier)) AS id_statut_metier,
    gm.metier_actif AS metier_actif
FROM gem_metier gm, gem_metier_competence gmc
WHERE gmc.code_metier IS NOT NULL;

COMMENT ON TABLE metier IS 'Table centrale des métiers de l''entreprise';
COMMENT ON COLUMN metier.code_metier IS 'Code unique du métier';
COMMENT ON COLUMN metier.id_neobrain_metier IS 'Identifiant interne Neobrain du métier';
COMMENT ON COLUMN metier.metier_collaborateur IS 'Nom usuel du métier';
COMMENT ON COLUMN metier.id_famille_metier IS 'Référence à la famille de métiers';
COMMENT ON COLUMN metier.id_statut_metier IS 'Référence au statut de publication du métier';
COMMENT ON COLUMN metier.metier_actif IS 'Indicateur d''activité du métier';

CREATE TABLE referentiel_competence (
    id_referentiel_competence VARCHAR PRIMARY KEY NOT NULL,
    libelle VARCHAR NOT NULL,
    type_referentiel VARCHAR NOT NULL,
    type_referentiel_detaille VARCHAR NOT NULL
);

INSERT INTO referentiel_competence
SELECT
    formatter(nom) AS id_referentiel_competence,
    nom AS libelle,
    ARG_MAX(type_ref, type_ref) AS type_referentiel,
    ARG_MAX(type_ref_detail, type_ref_detail) AS type_referentiel_detaille
FROM (
    SELECT referentiel_competence AS nom, type_referentiel_competence AS type_ref, type_referentiel_competence_detaille AS type_ref_detail FROM gem_competence
    UNION
    SELECT referentiel_competence AS nom, NULL, NULL FROM gem_metier_competence
)
GROUP BY nom;

COMMENT ON TABLE referentiel_competence IS 'Référentiels sources (ex: Neobrain, OPT-NC 2025)';
COMMENT ON COLUMN referentiel_competence.id_referentiel_competence IS 'Identifiant unique du référentiel (généré par formatter)';
COMMENT ON COLUMN referentiel_competence.libelle IS 'Nom complet du référentiel de compétences';
COMMENT ON COLUMN referentiel_competence.type_referentiel IS 'Catégorie principale du référentiel';
COMMENT ON COLUMN referentiel_competence.type_referentiel_detaille IS 'Catégorie détaillée du référentiel';

CREATE TABLE groupe_competence (
    id_groupe_competence VARCHAR PRIMARY KEY NOT NULL,
    libelle VARCHAR NOT NULL,
    type_groupe VARCHAR
);

INSERT INTO groupe_competence
SELECT
    formatter(nom) AS id_groupe_competence,
    nom AS libelle,
    ARG_MAX(type_grp, type_grp) AS type_groupe
FROM (
    SELECT groupe_competence AS nom, type_groupe_competence AS type_grp FROM gem_competence
    UNION ALL
    SELECT groupe_competence AS nom, NULL FROM gem_metier_competence
)
GROUP BY nom;

COMMENT ON TABLE groupe_competence IS 'Groupes de classification (ex: Savoir-faire, Savoir-être)';
COMMENT ON COLUMN groupe_competence.id_groupe_competence IS 'Identifiant unique du groupe (généré par formatter)';
COMMENT ON COLUMN groupe_competence.libelle IS 'Nom complet du groupe de compétences';
COMMENT ON COLUMN groupe_competence.type_groupe IS 'Type abstrait du groupe';

CREATE TABLE categorie_detention (
    id_categorie_detention VARCHAR PRIMARY KEY NOT NULL,
    libelle VARCHAR NOT NULL,
    gamme_detention VARCHAR NOT NULL
);

INSERT INTO categorie_detention
SELECT DISTINCT
    formatter(categorie_detention) AS id_categorie_detention,
    categorie_detention AS libelle_categorie,
    gamme_detention AS gamme_detention
FROM gem_competence
WHERE categorie_detention IS NOT NULL
AND gamme_detention IS NOT NULL;

COMMENT ON TABLE categorie_detention IS 'Niveaux de classification de la possession d''une compétence';
COMMENT ON COLUMN categorie_detention.id_categorie_detention IS 'Identifiant unique de la catégorie (généré par formatter)';
COMMENT ON COLUMN categorie_detention.libelle IS 'Nom de la catégorie de détention (ex: Well held)';
COMMENT ON COLUMN categorie_detention.gamme_detention IS 'Échelle ou plage représentant cette détention';

CREATE TABLE competence (
    code_competence VARCHAR PRIMARY KEY NOT NULL,
    id_neobrain_competence BIGINT NOT NULL,
    id_groupe_competence VARCHAR NOT NULL,
    id_referentiel_competence VARCHAR NOT NULL,
    CONSTRAINT fk_competence_groupe
        FOREIGN KEY (id_groupe_competence) REFERENCES groupe_competence(id_groupe_competence),
    CONSTRAINT fk_competence_referentiel
        FOREIGN KEY (id_referentiel_competence) REFERENCES referentiel_competence(id_referentiel_competence)
);

CREATE INDEX idx_competence_id_groupe ON competence(id_groupe_competence);
CREATE INDEX idx_competence_id_referentiel ON competence(id_referentiel_competence);

INSERT INTO competence
SELECT
    code AS code_competence,
    ARG_MAX(id, date_maj) AS id_neobrain_competence,
    ARG_MAX(id_grp, date_maj) AS id_groupe_competence,
    ARG_MAX(id_ref, date_maj) AS id_referentiel_competence
FROM (
    SELECT
        id_neobrain_competence AS id,
        code_competence AS code,
        formatter(groupe_competence) AS id_grp,
        formatter(referentiel_competence) AS id_ref,
        date_mise_a_jour AS date_maj
    FROM gem_competence
    UNION
    SELECT
        id_neobrain_competence AS id,
        code_competence AS code,
        formatter(groupe_competence) AS id_grp,
        formatter(referentiel_competence) AS id_ref,
        date_mise_a_jour AS date_maj
    FROM gem_metier_competence
    )
GROUP BY code;

COMMENT ON TABLE competence IS 'Catalogue central et unique des compétences (indépendant du nom)';
COMMENT ON COLUMN competence.code_competence IS 'Code de référence technique de la compétence';
COMMENT ON COLUMN competence.id_neobrain_competence IS 'Identifiant interne Neobrain';
COMMENT ON COLUMN competence.id_groupe_competence IS 'Lien vers le groupe de classification';
COMMENT ON COLUMN competence.id_referentiel_competence IS 'Lien vers le référentiel d''origine';

CREATE TABLE competence_utilisateur (
    code_competence VARCHAR PRIMARY KEY NOT NULL,
    nom_competence VARCHAR NOT NULL,
    id_categorie_detention VARCHAR NOT NULL,
    date_mise_a_jour TIMESTAMP NOT NULL,
    CONSTRAINT fk_cu_competence
        FOREIGN KEY (code_competence) REFERENCES competence(code_competence),
    CONSTRAINT fk_cu_categorie
        FOREIGN KEY (id_categorie_detention) REFERENCES categorie_detention(id_categorie_detention)
);

CREATE INDEX idx_competence_utilisateur_competence ON competence_utilisateur(code_competence);
CREATE INDEX idx_competence_utilisateur_categorie ON competence_utilisateur(id_categorie_detention);

INSERT INTO competence_utilisateur
SELECT DISTINCT
    code_competence,
    ARG_MAX(nom_competence, date_mise_a_jour) AS nom_competence,
    ARG_MAX(formatter(categorie_detention), date_mise_a_jour) AS id_cat,
    MAX(date_mise_a_jour) AS date_mise_a_jour
FROM gem_competence
WHERE code_competence IN (SELECT code_competence FROM competence)
GROUP BY code_competence;

COMMENT ON TABLE competence_utilisateur IS 'Profil de la compétence tel que perçu ou détenu par les collaborateurs';
COMMENT ON COLUMN competence_utilisateur.code_competence IS 'Référence à la compétence centrale';
COMMENT ON COLUMN competence_utilisateur.nom_competence IS 'Nom de la compétence affiché pour l''utilisateur';
COMMENT ON COLUMN competence_utilisateur.id_categorie_detention IS 'Catégorie globale de détention pour les utilisateurs';
COMMENT ON COLUMN competence_utilisateur.date_mise_a_jour IS 'Date de dernière modification du profil utilisateur';

CREATE TABLE niveau_description_competence (
    code_competence VARCHAR NOT NULL,
    niveau INTEGER NOT NULL,
    description TEXT NOT NULL,
    PRIMARY KEY (code_competence, niveau),
    CONSTRAINT fk_niveau_competence
       FOREIGN KEY (code_competence) REFERENCES competence_utilisateur(code_competence)
);

CREATE INDEX idx_niveau_description_comp_utilisateur ON niveau_description_competence(code_competence);

INSERT INTO niveau_description_competence
    SELECT code_competence, 1, description_niveau_1 AS description
    FROM gem_competence
    WHERE description_niveau_1 IS NOT NULL
UNION
    SELECT code_competence, 2, description_niveau_2 AS description
    FROM gem_competence
    WHERE description_niveau_2 IS NOT NULL
UNION
    SELECT code_competence, 3, description_niveau_3 AS description
    FROM gem_competence
    WHERE description_niveau_3 IS NOT NULL
UNION
    SELECT code_competence, 4, description_niveau_4 AS description
    FROM gem_competence
    WHERE description_niveau_4 IS NOT NULL;

COMMENT ON TABLE niveau_description_competence IS 'Descriptions textuelles des différents niveaux de maîtrise d''une compétence pour l''utilisateur';
COMMENT ON COLUMN niveau_description_competence.code_competence IS 'Référence à la compétence côté utilisateur';
COMMENT ON COLUMN niveau_description_competence.niveau IS 'Échelon de maîtrise (ex: 1 à 4)';
COMMENT ON COLUMN niveau_description_competence.description IS 'Explication détaillée des attentes pour ce niveau';

CREATE TABLE metier_competence (
    code_metier VARCHAR NOT NULL,
    code_competence VARCHAR NOT NULL,
    nom_competence VARCHAR NOT NULL,
    poids DOUBLE,
    niveau_requis DOUBLE,
    est_actif BOOLEAN NOT NULL,
    date_creation TIMESTAMP NOT NULL,
    date_mise_a_jour TIMESTAMP NOT NULL,
    PRIMARY KEY (code_metier, code_competence, nom_competence),
    CONSTRAINT fk_mc_metier
        FOREIGN KEY (code_metier) REFERENCES metier(code_metier),
    CONSTRAINT fk_mc_competence
       FOREIGN KEY (code_competence) REFERENCES competence(code_competence)
);

CREATE INDEX idx_metier_competence_competence ON metier_competence(code_competence);
CREATE INDEX idx_metier_competence_metier ON metier_competence(code_metier);

INSERT INTO metier_competence
SELECT
    code_metier AS code_metier,
    code_competence AS code_competence,
    nom_competence AS nom_competence,
    poids,
    niveau_requis,
    relation_metier_competence_active AS est_actif,
    date_creation,
    date_mise_a_jour
FROM gem_metier_competence
WHERE code_metier IN (SELECT code_metier FROM metier);

COMMENT ON TABLE metier_competence IS 'Table d''association définissant les besoins en compétences d''un métier spécifique';
COMMENT ON COLUMN metier_competence.code_metier IS 'Référence au métier demandeur';
COMMENT ON COLUMN metier_competence.code_competence IS 'Référence à la compétence requise';
COMMENT ON COLUMN metier_competence.nom_competence IS 'Nom spécifique de la compétence tel qu''employé dans le contexte de ce métier';
COMMENT ON COLUMN metier_competence.poids IS 'Importance relative de la compétence pour ce métier';
COMMENT ON COLUMN metier_competence.niveau_requis IS 'Niveau de maîtrise minimal attendu';
COMMENT ON COLUMN metier_competence.est_actif IS 'Statut d''activation de cette exigence pour le métier';
COMMENT ON COLUMN metier_competence.date_creation IS 'Date d''association initiale';
COMMENT ON COLUMN metier_competence.date_mise_a_jour IS 'Dernière modification de l''exigence';

CREATE TABLE about (
    key TEXT PRIMARY KEY,
    value TIMESTAMP NOT NULL
);

INSERT INTO about (key, value)
VALUES
    ('generation_date_utc', CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    ('generation_date_local', CURRENT_TIMESTAMP AT TIME ZONE 'Pacific/Noumea');

COMMENT ON TABLE about IS 'Métadonnées sur la génération de la base';
COMMENT ON COLUMN about.key IS 'Nom de la métadonnée';
COMMENT ON COLUMN about.value IS 'Valeur de la métadonnée';

CREATE OR REPLACE VIEW vw_lister_competences_metier AS
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
ORDER BY code_metier;

COMMENT ON VIEW vw_lister_competences_metier IS 'Vue détaillée des compétences requises par métier';
COMMENT ON COLUMN vw_lister_competences_metier.code_metier IS 'Code du métier';
COMMENT ON COLUMN vw_lister_competences_metier.metier_collaborateur IS 'Nom du métier';
COMMENT ON COLUMN vw_lister_competences_metier.code_competence IS 'Code de la compétence requise';
COMMENT ON COLUMN vw_lister_competences_metier.nom_competence IS 'Nom de la compétence côté métier';

CREATE OR REPLACE VIEW vw_compter_competences_par_metier AS
SELECT
    m.code_metier,
    m.metier_collaborateur,
    (SELECT COUNT(*) FROM metier_competence mc WHERE mc.code_metier = m.code_metier) AS nb_competences,
    (SELECT COUNT(*) FROM metier_competence mc WHERE mc.code_metier = m.code_metier AND mc.est_actif = true) AS nb_competences_actives,
    (SELECT AVG(mc.niveau_requis) FROM metier_competence mc WHERE mc.code_metier = m.code_metier) AS niveau_moyen_requis,
    (SELECT SUM(mc.poids) FROM metier_competence mc WHERE mc.code_metier = m.code_metier) AS poids_total
FROM metier m
ORDER BY nb_competences;

COMMENT ON VIEW vw_compter_competences_par_metier IS 'Vue agrégée résumant le profil de compétences de chaque métier';
COMMENT ON COLUMN vw_compter_competences_par_metier.code_metier IS 'Code unique du métier';
COMMENT ON COLUMN vw_compter_competences_par_metier.metier_collaborateur IS 'Nom usuel du métier';
COMMENT ON COLUMN vw_compter_competences_par_metier.nb_competences IS 'Nombre total de compétences associées';
COMMENT ON COLUMN vw_compter_competences_par_metier.nb_competences_actives IS 'Nombre de compétences actuellement actives';
COMMENT ON COLUMN vw_compter_competences_par_metier.niveau_moyen_requis IS 'Moyenne des niveaux requis';
COMMENT ON COLUMN vw_compter_competences_par_metier.poids_total IS 'Somme des poids des compétences requises';

CREATE OR REPLACE VIEW vw_competences_orphelines AS
SELECT
    c.code_competence,
    cu.nom_competence,
    g.libelle AS groupe_competence
FROM competence c
    JOIN competence_utilisateur cu ON c.code_competence = cu.code_competence
    JOIN groupe_competence g ON c.id_groupe_competence = g.id_groupe_competence
WHERE c.code_competence NOT IN (SELECT DISTINCT code_competence FROM metier_competence);

COMMENT ON VIEW vw_competences_orphelines IS 'Liste des compétences du catalogue qui ne sont requises par aucun métier actif';
COMMENT ON COLUMN vw_competences_orphelines.code_competence IS 'Code de la compétence isolée';
COMMENT ON COLUMN vw_competences_orphelines.nom_competence IS 'Nom de la compétence côté utilisateur';
COMMENT ON COLUMN vw_competences_orphelines.groupe_competence IS 'Groupe d''appartenance';

CREATE OR REPLACE VIEW vw_competences_architecte_logiciel AS
SELECT
    (SELECT gc.libelle FROM groupe_competence gc WHERE c.id_groupe_competence = gc.id_groupe_competence) AS groupe_competence,
    m.metier_collaborateur,
    cu.code_competence,
    mc.nom_competence AS nom_competence_metier,
    mc.niveau_requis,
    (SELECT ndc.description FROM niveau_description_competence ndc WHERE cu.code_competence = ndc.code_competence AND ndc.niveau = CAST(mc.niveau_requis AS INTEGER)) AS description_niveau_requis
FROM metier m
JOIN metier_competence mc ON m.code_metier = mc.code_metier
JOIN competence_utilisateur cu ON mc.code_competence = cu.code_competence
JOIN competence c ON mc.code_competence = c.code_competence
WHERE m.metier_collaborateur ILIKE '%Architecte%logiciel%';

COMMENT ON VIEW vw_competences_architecte_logiciel IS 'Vue listant les compétences, le métier et la description du niveau requis spécifiquement pour le métier Architecte Logiciel';
COMMENT ON COLUMN vw_competences_architecte_logiciel.groupe_competence IS 'Groupe de classification de la compétence (ex: Savoir-faire, Savoir-être)';
COMMENT ON COLUMN vw_competences_architecte_logiciel.metier_collaborateur IS 'Nom du métier';
COMMENT ON COLUMN vw_competences_architecte_logiciel.code_competence IS 'Code technique de la compétence';
COMMENT ON COLUMN vw_competences_architecte_logiciel.nom_competence_metier IS 'Nom de la compétence dans le référentiel métier';
COMMENT ON COLUMN vw_competences_architecte_logiciel.niveau_requis IS 'Échelon de maîtrise exigé (ex: 1, 2, 3 ou 4)';
COMMENT ON COLUMN vw_competences_architecte_logiciel.description_niveau_requis IS 'Explication textuelle de ce qui est attendu pour ce niveau précis';

CREATE OR REPLACE VIEW vw_metiers_orphelins AS
SELECT
    m.code_metier,
    m.metier_collaborateur,
    fm.libelle AS famille_metier,
    stm.libelle AS statut_metier,
    m.metier_actif
FROM metier m
    JOIN famille_metier fm ON m.id_famille_metier = fm.id_famille_metier
    JOIN statut_metier stm ON m.id_statut_metier = stm.id_statut_metier
WHERE m.code_metier NOT IN (SELECT DISTINCT code_metier FROM metier_competence);

COMMENT ON VIEW vw_metiers_orphelins IS 'Liste des métiers sans aucune compétence associée';
COMMENT ON COLUMN vw_metiers_orphelins.code_metier IS 'Code unique du métier';
COMMENT ON COLUMN vw_metiers_orphelins.metier_collaborateur IS 'Nom du métier';
COMMENT ON COLUMN vw_metiers_orphelins.famille_metier IS 'Famille du métier';
COMMENT ON COLUMN vw_metiers_orphelins.statut_metier IS 'Statut de publication du métier';
COMMENT ON COLUMN vw_metiers_orphelins.metier_actif IS 'Indique si le métier est actif';

-- REPORTING
FROM vw_metiers_orphelins;
FROM vw_competences_orphelines;

-- EXPORTS
INSTALL sqlite;
LOAD sqlite;

ATTACH 'dist/ref-metiers-opt-nc.sqlite' AS sqlite_db (TYPE sqlite);

DROP TABLE IF EXISTS sqlite_db.famille_metier;
DROP TABLE IF EXISTS sqlite_db.statut_metier;
DROP TABLE IF EXISTS sqlite_db.metier;
DROP TABLE IF EXISTS sqlite_db.referentiel_competence;
DROP TABLE IF EXISTS sqlite_db.groupe_competence;
DROP TABLE IF EXISTS sqlite_db.categorie_detention;
DROP TABLE IF EXISTS sqlite_db.competence;
DROP TABLE IF EXISTS sqlite_db.competence_utilisateur;
DROP TABLE IF EXISTS sqlite_db.niveau_description_competence;
DROP TABLE IF EXISTS sqlite_db.metier_competence;
DROP TABLE IF EXISTS sqlite_db.about;

CREATE TABLE sqlite_db.famille_metier AS
SELECT * FROM famille_metier;

CREATE TABLE sqlite_db.statut_metier AS
SELECT * FROM statut_metier;

CREATE TABLE sqlite_db.metier AS
SELECT * FROM metier;

CREATE TABLE sqlite_db.referentiel_competence AS
SELECT * FROM referentiel_competence;

CREATE TABLE sqlite_db.groupe_competence AS
SELECT * FROM groupe_competence;

CREATE TABLE sqlite_db.categorie_detention AS
SELECT * FROM categorie_detention;

CREATE TABLE sqlite_db.competence AS
SELECT * FROM competence;

CREATE TABLE sqlite_db.competence_utilisateur AS
SELECT * FROM competence_utilisateur;

CREATE TABLE sqlite_db.niveau_description_competence AS
SELECT * FROM niveau_description_competence;

CREATE TABLE sqlite_db.metier_competence AS
SELECT * FROM metier_competence;

CREATE TABLE sqlite_db.about AS
SELECT * FROM about;

EXPORT DATABASE 'data/output';
