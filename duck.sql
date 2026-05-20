DROP MACRO IF EXISTS formatter;
CREATE MACRO formatter(str) AS (
    TRIM(
        BOTH '_' FROM
        REGEXP_REPLACE(
            LOWER(
                TRANSLATE(
                    COALESCE(str, ''),
                    'éèêëàâäîïôöùûüç',
                    'eeeeaaaiioouuuc'
                )
            ),
            '[^a-z0-9]+',
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

DROP TABLE IF EXISTS sous_famille_metier;
DROP TABLE IF EXISTS statut_metier;
DROP TABLE IF EXISTS referentiel_competence;
DROP TABLE IF EXISTS groupe_competence;
DROP TABLE IF EXISTS categorie_detention;

DROP TABLE IF EXISTS about;

DROP INDEX IF EXISTS idx_famille_metier_sous_famille;
DROP INDEX IF EXISTS idx_metier_famille;
DROP INDEX IF EXISTS idx_metier_statut;
DROP INDEX IF EXISTS idx_competence_groupe;
DROP INDEX IF EXISTS idx_competence_referentiel;
DROP INDEX IF EXISTS idx_competence_utilisateur_categorie;
DROP INDEX IF EXISTS idx_niveau_description_comp_utilisateur;
DROP INDEX IF EXISTS idx_metier_competence_competence;
DROP INDEX IF EXISTS idx_metier_competence_metier;

CREATE TEMP TABLE gem_metier AS SELECT * FROM read_csv_auto('data/input/gem_metiers.csv');
CREATE TEMP TABLE gem_competence AS SELECT * FROM read_csv_auto('data/input/gem_competences.csv') WHERE "Code de compétence" IS NOT NULL;
CREATE TEMP TABLE gem_metier_competence AS SELECT * FROM read_csv_auto('data/input/gem_metiers_competences.csv') WHERE "Code de compétence" IS NOT NULL;


CREATE TABLE sous_famille_metier (
     id_sous_famille_metier VARCHAR PRIMARY KEY NOT NULL,
     libelle VARCHAR NOT NULL
);

INSERT INTO sous_famille_metier
SELECT DISTINCT
    NULLIF(formatter("Sous-famille métier"), '') AS id_sous_famille_metier,
    "Sous-famille métier" AS libelle
FROM gem_metier
WHERE "Sous-famille métier" IS NOT NULL;

COMMENT ON TABLE sous_famille_metier IS 'Sous-familles de classification des métiers';
COMMENT ON COLUMN sous_famille_metier.id_sous_famille_metier IS 'Identifiant unique de la sous-famille (généré par formatter)';
COMMENT ON COLUMN sous_famille_metier.libelle IS 'Nom complet de la sous-famille de métiers';

CREATE TABLE famille_metier (
    id_famille_metier VARCHAR PRIMARY KEY NOT NULL,
    libelle VARCHAR NOT NULL,
    description VARCHAR,
    id_sous_famille_metier VARCHAR,
    CONSTRAINT fk_famille_sous_famille
        FOREIGN KEY (id_sous_famille_metier) REFERENCES sous_famille_metier(id_sous_famille_metier)
);

CREATE INDEX idx_famille_metier_sous_famille ON famille_metier(id_sous_famille_metier);

INSERT INTO famille_metier
SELECT DISTINCT
    NULLIF(formatter("Famille métier"), '') AS id_famille_metier,
    "Famille métier" AS libelle,
    NULL AS description,
    NULLIF(formatter("Sous-famille métier"), '') AS id_sous_famille_metier
FROM gem_metier
WHERE NULLIF(formatter("Famille métier"), '') IS NOT NULL;

COMMENT ON TABLE famille_metier IS 'Familles de métiers possiblement rattachées à une sous-famille';
COMMENT ON COLUMN famille_metier.id_famille_metier IS 'Identifiant unique de la famille (généré par formatter)';
COMMENT ON COLUMN famille_metier.libelle IS 'Libellé complet de la famille de métiers';
COMMENT ON COLUMN famille_metier.description IS 'Description optionnelle de la famille';
COMMENT ON COLUMN famille_metier.id_sous_famille_metier IS 'Référence à la sous-famille parente';

CREATE TABLE statut_metier (
    id_statut_metier VARCHAR PRIMARY KEY,
    libelle VARCHAR NOT NULL
);

INSERT INTO statut_metier
SELECT DISTINCT
    UPPER(formatter(statut)) AS id_statut_metier,
    statut AS libelle
FROM (
    SELECT DISTINCT "Statut du métier" AS statut
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
    gmc."Code Métier" AS code_metier,
    gmc."Id Neobrain Métier" AS id_neobrain_metier,
    gmc."Métier collaborateur" AS metier_collaborateur,
    NULLIF(formatter(gmc."Famille métier"), '') AS id_famille_metier,
    NULLIF(UPPER(formatter(gm."Statut du métier")), '') AS id_statut_metier,
    CAST(gm."Métier actif?" AS BOOLEAN) AS metier_actif
FROM gem_metier gm, gem_metier_competence gmc
WHERE gmc."Code Métier" IS NOT NULL;

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
SELECT DISTINCT
    formatter(list.nom) AS id_referentiel_competence,
    list.nom AS libelle,
    ref.type_ref AS type_referentiel,
    ref.type_ref_detail AS type_referentiel_detaille
FROM (
         SELECT "Référentiel de compétences" AS nom FROM gem_competence
         UNION
         SELECT "Référentiel de compétences" AS nom FROM gem_metier_competence
    ) list
    LEFT JOIN (
    SELECT DISTINCT
        "Référentiel de compétences" AS nom,
        "Type de référentiel de compétences" AS type_ref,
        "Type de référentiel de compétences détaillé" AS type_ref_detail
    FROM gem_competence
) ref ON list.nom = ref.nom
WHERE list.nom IS NOT NULL;

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
SELECT DISTINCT
    formatter(list.nom) AS id_groupe_competence,
    list.nom AS libelle,
    grp.type_grp AS type_groupe
FROM (
         SELECT "Groupe de compétences" AS nom FROM gem_competence
         UNION
         SELECT "Groupe de compétences" AS nom FROM gem_metier_competence
     ) list
         LEFT JOIN (
    SELECT DISTINCT
        "Groupe de compétences" AS nom,
        "Type de groupe de compétences" AS type_grp
    FROM gem_competence
) grp ON list.nom = grp.nom
WHERE COALESCE(TRIM(list.nom), '') <> '';

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
    formatter("Catégorie de détention de compétences") AS id_categorie_detention,
    "Catégorie de détention de compétences" AS libelle_categorie,
    "Gamme de détention dans les métiers de la compétence" AS gamme_detention
FROM gem_competence
WHERE "Catégorie de détention de compétences" IS NOT NULL
  AND "Gamme de détention dans les métiers de la compétence" IS NOT NULL;

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
        "Id interne Neobrain Compétence" AS id,
        "Code de compétence" AS code,
        NULLIF(formatter("Groupe de compétences"), '') AS id_grp,
        NULLIF(formatter("Référentiel de compétences"), '') AS id_ref,
        "Compétence mise à jour le" AS date_maj
    FROM gem_competence
    UNION ALL
    SELECT
        "Id interne Neobrain Compétence" AS id,
        "Code de compétence" AS code,
        NULLIF(formatter("Groupe de compétences"), '') AS id_grp,
        NULLIF(formatter("Référentiel de compétences"), '') AS id_ref,
        "Relation Métier-Compétence mise à jour le" AS date_maj
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
SELECT
    "Code de compétence",
    ARG_MAX("Nom de la compétence", "Compétence mise à jour le") AS nom_competence,
    ANY_VALUE(NULLIF(formatter("Catégorie de détention de compétences"), '')) AS id_cat,
    MAX("Compétence mise à jour le") AS date_mise_a_jour
FROM gem_competence
WHERE "Code de compétence" IN (SELECT code_competence FROM competence)
GROUP BY "Code de compétence";

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
    SELECT "Code de compétence", 1, ANY_VALUE("Description Niveau 1 Compétence")
    FROM gem_competence
    WHERE "Description Niveau 1 Compétence" IS NOT NULL
    AND "Code de compétence" IN (SELECT code_competence FROM competence_utilisateur)
    GROUP BY "Code de compétence"
UNION ALL
    SELECT "Code de compétence", 2, ANY_VALUE("Description Niveau 2 Compétence")
    FROM gem_competence
    WHERE "Description Niveau 2 Compétence" IS NOT NULL
    AND "Code de compétence" IN (SELECT code_competence FROM competence_utilisateur)
    GROUP BY "Code de compétence"
UNION ALL
    SELECT "Code de compétence", 3, ANY_VALUE("Description Niveau 3 Compétence")
    FROM gem_competence
    WHERE "Description Niveau 3 Compétence" IS NOT NULL
    AND "Code de compétence" IN (SELECT code_competence FROM competence_utilisateur)
    GROUP BY "Code de compétence"
UNION ALL
    SELECT "Code de compétence", 4, ANY_VALUE("Description Niveau 4 Compétence")
    FROM gem_competence
    WHERE "Description Niveau 4 Compétence" IS NOT NULL
    AND "Code de compétence" IN (SELECT code_competence FROM competence_utilisateur)
    GROUP BY "Code de compétence";

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
    "Code Métier" AS code_metier,
    "Code de compétence" AS code_competence,
    "Nom de la compétence" AS nom_competence,
    CASE
        WHEN ARG_MAX("Poids de la compétence", "Relation Métier-Compétence mise à jour le") > 0 THEN ARG_MAX("Poids de la compétence", "Relation Métier-Compétence mise à jour le")
        ELSE 0
        END AS poids,
    CASE
        WHEN ARG_MAX("Niveau requis pour le métier", "Relation Métier-Compétence mise à jour le") THEN ARG_MAX("Niveau requis pour le métier", "Relation Métier-Compétence mise à jour le")
        ELSE 0
        END AS niveau_requis,
    ARG_MAX(LOWER(CAST("Relation Métier-Compétence active?" AS VARCHAR)) = 'true', "Relation Métier-Compétence mise à jour le") AS est_actif,
    MIN("Relation Métier-Compétence créée le") AS date_creation,
    MAX("Relation Métier-Compétence mise à jour le") AS date_mise_a_jour
FROM gem_metier_competence
WHERE "Code Métier" IN (SELECT code_metier FROM metier)
    AND "Code de compétence" IN (SELECT code_competence FROM competence)
    AND "Nom de la compétence" IS NOT NULL
GROUP BY
    "Code Métier",
    "Code de compétence",
    "Nom de la compétence";

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
FROM metier m
    JOIN metier_competence mc ON m.code_metier = mc.code_metier
    JOIN competence c ON mc.code_competence = c.code_competence
    LEFT JOIN groupe_competence g ON c.id_groupe_competence = g.id_groupe_competence
    LEFT JOIN referentiel_competence r ON c.id_referentiel_competence = r.id_referentiel_competence
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
    COUNT(mc.code_competence) AS nb_competences,
    COUNT(CASE WHEN mc.est_actif THEN 1 END) AS nb_competences_actives,
    AVG(mc.niveau_requis) AS niveau_moyen_requis,
    SUM(mc.poids) AS poids_total
FROM metier m
    LEFT JOIN metier_competence mc ON m.code_metier = mc.code_metier
GROUP BY m.code_metier, m.metier_collaborateur
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
    LEFT JOIN competence_utilisateur cu ON c.code_competence = cu.code_competence
    LEFT JOIN metier_competence mc ON c.code_competence = mc.code_competence
    LEFT JOIN groupe_competence g ON c.id_groupe_competence = g.id_groupe_competence
WHERE mc.code_competence IS NULL;

COMMENT ON VIEW vw_competences_orphelines IS 'Liste des compétences du catalogue qui ne sont requises par aucun métier actif';
COMMENT ON COLUMN vw_competences_orphelines.code_competence IS 'Code de la compétence isolée';
COMMENT ON COLUMN vw_competences_orphelines.nom_competence IS 'Nom de la compétence côté utilisateur';
COMMENT ON COLUMN vw_competences_orphelines.groupe_competence IS 'Groupe d''appartenance';

CREATE OR REPLACE VIEW vw_competences_architecte_logiciel AS
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
    sm.libelle AS sous_famille_metier,
    stm.libelle AS statut_metier,
    m.metier_actif
FROM metier m
    LEFT JOIN famille_metier fm ON m.id_famille_metier = fm.id_famille_metier
    LEFT JOIN sous_famille_metier sm ON fm.id_sous_famille_metier = sm.id_sous_famille_metier
    LEFT JOIN statut_metier stm ON m.id_statut_metier = stm.id_statut_metier
    LEFT JOIN metier_competence mc ON m.code_metier = mc.code_metier
WHERE mc.code_metier IS NULL;

COMMENT ON VIEW vw_metiers_orphelins IS 'Liste des métiers sans aucune compétence associée';
COMMENT ON COLUMN vw_metiers_orphelins.code_metier IS 'Code unique du métier';
COMMENT ON COLUMN vw_metiers_orphelins.metier_collaborateur IS 'Nom du métier';
COMMENT ON COLUMN vw_metiers_orphelins.famille_metier IS 'Famille du métier';
COMMENT ON COLUMN vw_metiers_orphelins.sous_famille_metier IS 'Sous-famille du métier';
COMMENT ON COLUMN vw_metiers_orphelins.statut_metier IS 'Statut de publication du métier';
COMMENT ON COLUMN vw_metiers_orphelins.metier_actif IS 'Indique si le métier est actif';
