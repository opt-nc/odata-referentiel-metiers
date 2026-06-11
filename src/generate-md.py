import os
from html import escape

import duckdb

DUCK_DB = "dist/ref-metiers-opt-nc.duckdb"
SITE_DIR = "site"

# Descriptions affichées en introduction de chaque groupe de compétences.
GROUPE_DESCRIPTIONS = {
    "savoir": "Le savoir regroupe les connaissances théoriques et techniques utiles pour comprendre et exercer un métier.",
    "savoir faire": "Le savoir-faire correspond à la capacité de mettre ses connaissances en pratique pour réaliser une activité ou accomplir une tâche.",
    "savoir être": "Le savoir-être rassemble les attitudes, comportements et qualités relationnelles qui facilitent l'adaptation au travail et les échanges avec les autres.",
    "manager": "Le savoir-manager regroupe les aptitudes liées à l'encadrement, au pilotage d'activité, au leadership et à l'accompagnement des équipes.",
}

# Icônes Font Awesome utilisées dans le menu latéral Relearn.
MENU_ICONS = {
    "home": "clipboard-list",
    "introduction": "info-circle",
    "niveaux": "graduation-cap",
    "familles": "list-ul",
    "metier": "id-card",
    "competence": "book",
}

# Shortcodes Hugo/Relearn utilisés directement dans le contenu Markdown.
CONTENT_ICONS = {
    "resume": '{{< icon "clipboard-list" "blue" >}}',
    "automatisation": '{{< icon "cogs" "grey" >}}',
    "drh": '{{< icon "comments" "blue" >}}',
    "description_niveaux": '{{< icon "list-ul" "grey" >}}',
    "competence": '{{< icon "book" >}}',
    "niveau_plein": '{{< icon "fa-fw fas fa-circle" "blue" >}}',
    "niveau_vide": '{{< icon "fa-fw far fa-circle" "grey" >}}',
}

HOME_MD = """+++
title = "Référentiel Métiers OPT-NC"
type = "home"

+++

## {{< icon "clipboard-list" "blue" >}} Résumé

Ce document présente le référentiel des métiers de l'OPT-NC. Il rassemble les familles professionnelles, les fiches emplois et les compétences attendues pour chaque métier.

Chaque fiche détaille les compétences associées au poste et indique le niveau de maîtrise requis. Ces niveaux permettent de mieux comprendre les attentes, de se situer dans son parcours professionnel et d'identifier les axes de progression possibles.

Le référentiel est généré automatiquement à partir de données structurées. Cette approche permet de produire une documentation cohérente, lisible et plus simple à maintenir dans le temps.
"""


INTRODUCTION_MD = """+++
title = "Introduction"
weight = 1

+++

## {{< icon "cogs" "grey" >}} Pourquoi une démarche de documentation automatisée ?

Ce référentiel a été généré à partir de données structurées afin de produire une documentation claire, homogène et facilement maintenable.

L'objectif n'est pas simplement de produire un document final, mais de mettre en place une chaîne reproductible. Les données sont chargées dans une base DuckDB, contrôlées, analysées, puis transformées automatiquement en documentation.

Concrètement, la génération s'appuie sur les scripts du projet pour construire les bases de données, produire les exports et préparer les contenus destinés aux différents formats de publication.

Cette approche permet de garder une source de données structurée, de produire automatiquement une documentation lisible, et de faciliter les mises à jour lorsque les données ou le modèle évoluent.

---

## {{< icon "comments" "blue" >}} Le mot de la Direction des Ressources Humaines

> Huit ans. C'est le temps qui s'est écoulé depuis la toute première édition de notre répertoire en 2017. Aujourd'hui, je suis particulièrement heureuse de partager avec vous sa nouvelle version.
>
> En huit ans, l'Office a changé, notre environnement aussi, et nos métiers se sont inévitablement transformés. Cette mise à jour était donc essentielle pour refléter la réalité de notre quotidien.
>
> Aujourd'hui, ce sont **84 fiches emplois**, réparties en **12 grandes familles professionnelles**, qui ont été redessinées. Pour chacune d'entre elles, vous trouverez une description claire des missions, des responsabilités et des compétences attendues. Au fur et à mesure, nous viendrons même y ajouter de nouvelles informations.
>
> Mais ce répertoire va bien au-delà d'un simple "catalogue" d'emplois. Il représente notre véritable boussole commune pour valoriser nos talents internes actuels, tout en nous préparant aux compétences dont nous aurons besoin demain.
>
> C'est d'ailleurs exactement pour cela que nous déployons en parallèle la plateforme **GEM**. Cet espace numérique est votre nouvel outil pour faire le point sur vos compétences, mettre en lumière vos atouts, et pourquoi pas, repérer de nouvelles opportunités d'évolution au sein de l'OPT-NC.
>
> Je tiens à remercier chaleureusement toutes les équipes qui ont donné vie à ce projet. Ce répertoire et la plateforme GEM sont entre vos mains : ce sont d'excellents leviers pour construire votre propre parcours, renforcer vos équipes, et participer à l'avenir de l'OPT-NC.
>
> **Eloïse NICOLAS**  
> Directrice des Ressources Humaines
"""

NIVEAU_COMPETENCE_MD = """+++
title = "Niveaux de compétences"
weight = 2

+++

## {{< icon "list-ul" "grey" >}} Description des niveaux de compétences

Dans chaque fiche emploi du répertoire, un niveau est indiqué pour les compétences attendues. Il permet de mieux comprendre le degré de maîtrise nécessaire pour exercer le poste dans de bonnes conditions.

L'échelle comporte quatre niveaux. Elle va des premières notions jusqu'à une maîtrise reconnue. Elle sert de repère commun pour savoir ce qui est attendu, situer son propre niveau et repérer les points à renforcer.

Ces niveaux peuvent aussi aider à se préparer dans le cadre d'une mobilité, d'un changement de poste ou d'un projet professionnel.
"""


NIVEAUX_COMPETENCE = [
    (1, "Notions", "La personne connaît les bases du domaine. Elle peut réaliser des tâches simples, mais elle a encore besoin d'être accompagnée pour avancer avec confiance."),
    (2, "Intermédiaire", "La personne possède une compréhension générale du sujet. Elle peut réaliser les tâches courantes de manière autonome, même si elle doit encore consolider sa pratique et gagner en expérience."),
    (3, "Avancé", "La personne maîtrise bien le domaine, aussi bien dans la théorie que dans la pratique. Son expérience lui permet de gérer seule des situations variées, y compris lorsqu'elles sont plus complexes."),
    (4, "Expert", "La personne est reconnue comme une référence dans son domaine. Elle sait traiter des situations inhabituelles, proposer des solutions adaptées et transmettre ses connaissances aux autres."),
]


def toml_string(value: str) -> str:
    """Entoure le texte avec des guillemets pour le front matter Hugo."""
    return f'"{value}"'


def menu_pre(icon: str) -> str:
    """Construit l'icône Font Awesome affichée avant un titre de menu."""
    return toml_string(f"<i class='fa-fw fas fa-{icon}'></i> ")


def html_table_cell(value: str) -> str:
    """Prépare une valeur texte pour une cellule HTML."""
    return escape(" ".join(value.splitlines()), quote=False)


def niveau_score(niveau: float | int | None, max_niveau: int = 4) -> str:
    """Convertit un niveau numérique en quatre icônes Font Awesome."""
    if niveau is None:
        return "-"

    niveau_int = int(niveau)
    return " ".join(
        [CONTENT_ICONS["niveau_plein"]] * niveau_int
        + [CONTENT_ICONS["niveau_vide"]] * (max_niveau - niveau_int)
    )


def write_home(site_dir: str) -> str:
    """Écrit la page d'accueil du site."""
    home_file = os.path.join(site_dir, "content", "_index.md")
    os.makedirs(os.path.dirname(home_file), exist_ok=True)
    with open(home_file, "w", encoding="utf-8") as f:
        f.write(HOME_MD)
    return home_file


def write_introduction(site_dir: str) -> str:
    """Écrit la page d'introduction, placée juste après l'accueil."""
    introduction_file = os.path.join(site_dir, "content", "introduction", "_index.md")
    os.makedirs(os.path.dirname(introduction_file), exist_ok=True)
    with open(introduction_file, "w", encoding="utf-8") as f:
        f.write(INTRODUCTION_MD)
    return introduction_file


def write_niveaux_competence(site_dir: str) -> str:
    """Écrit la page qui décrit l'échelle des niveaux de compétences."""
    niveaux_file = os.path.join(site_dir, "content", "niveaux-competences", "_index.md")
    os.makedirs(os.path.dirname(niveaux_file), exist_ok=True)

    content = NIVEAU_COMPETENCE_MD.rstrip() + "\n\n"
    for niveau, label, description in NIVEAUX_COMPETENCE:
        content += f"### Niveau {niveau} - {label} {niveau_score(niveau)}\n\n"
        content += f"{description}\n\n"

    with open(niveaux_file, "w", encoding="utf-8") as f:
        f.write(content)
    return niveaux_file


def fetch_familles(conn: duckdb.DuckDBPyConnection) -> list[tuple[str, str]]:
    """Récupère les familles qui possèdent au moins un métier actif."""
    return conn.execute("""
        SELECT DISTINCT fm.famille_metier_id, fm.libelle
        FROM famille_metier fm
        JOIN metier m on fm.famille_metier_id = m.famille_metier_id
        WHERE m.metier_actif = true
        GROUP BY fm.famille_metier_id, fm.libelle
        ORDER BY MAX(m.code_metier)
    """).fetchall()


def fetch_metiers(conn: duckdb.DuckDBPyConnection, famille_id: str) -> list[tuple[str, str]]:
    """Récupère les métiers actifs d'une famille."""
    return conn.execute("""
        SELECT code_metier, metier_collaborateur
        FROM metier
        WHERE famille_metier_id = ?
        AND metier_actif = true
        ORDER BY code_metier
    """, [famille_id]).fetchall()


def fetch_groupes_competence(conn: duckdb.DuckDBPyConnection, code_metier: str) -> list[tuple[str]]:
    """Récupère les groupes de compétences associés à un métier."""
    return conn.execute("""
        SELECT DISTINCT gc.libelle
        FROM metier_competence mc
        JOIN competence c ON mc.code_competence = c.code_competence
        JOIN groupe_competence gc ON c.groupe_competence_id = gc.groupe_competence_id
        WHERE mc.code_metier = ?
        ORDER BY gc.libelle
    """, [code_metier]).fetchall()


def fetch_competences(conn: duckdb.DuckDBPyConnection, code_metier: str, libelle_groupe: str) -> list[tuple[str, int]]:
    """Récupère les compétences et leur niveau pour un métier."""
    return conn.execute("""
        SELECT DISTINCT mc.nom_competence, mc.niveau_requis
        FROM metier_competence mc
        JOIN competence c ON mc.code_competence = c.code_competence
        JOIN groupe_competence gc ON c.groupe_competence_id = gc.groupe_competence_id
        JOIN niveau_description_competence ndc ON mc.code_competence = ndc.code_competence
        WHERE mc.code_metier = ?
        AND gc.libelle = ?
        ORDER BY mc.nom_competence ASC
    """, [code_metier, libelle_groupe]).fetchall()


def write_competences_groupe(conn: duckdb.DuckDBPyConnection, code_metier: str, libelle_groupe: str) -> str:
    """Construit la section Markdown d'un groupe de compétences."""
    content = f"## {CONTENT_ICONS['competence']} {libelle_groupe.capitalize()}\n\n"

    description = GROUPE_DESCRIPTIONS.get(libelle_groupe.lower())
    if description:
        content += f"> {description}\n\n"

    # On ne peut pas configurer les largeurs de colonnes dans Markdown, donc on génère un tableau HTML en conséquence.
    competences = fetch_competences(conn, code_metier, libelle_groupe)
    content += '<table class="competences-table">\n'
    content += "  <colgroup>\n"
    content += '    <col style="width: 85%;">\n'
    content += '    <col style="width: 15%;">\n'
    content += "  </colgroup>\n"
    content += "  <thead>\n"
    content += "    <tr>\n"
    content += "      <th>Compétence</th>\n"
    content += '      <th style="text-align: center;">Score</th>\n'
    content += "    </tr>\n"
    content += "  </thead>\n"
    content += "  <tbody>\n"

    for nom_competence, niveau in competences:
        content += "    <tr>\n"
        content += f"      <td>{html_table_cell(nom_competence)}</td>\n"
        content += f'      <td style="text-align: center;">{niveau_score(niveau)}</td>\n'
        content += "    </tr>\n"

    content += "  </tbody>\n"
    content += "</table>\n"

    return content + "\n"


def write_metier(famille_dir: str, conn: duckdb.DuckDBPyConnection, index_metier: int, code_metier: str, nom_metier: str) -> str:
    """Écrit la page Markdown d'un métier."""
    metier_dir = os.path.join(famille_dir, code_metier.lower())
    os.makedirs(metier_dir, exist_ok=True)
    metier_file = os.path.join(metier_dir, "_index.md")

    content = f"""+++
title = {toml_string(f"{code_metier} - {nom_metier}")}
weight = {index_metier}

+++

"""

    # Un groupe de compétences = une section dans la page métier.
    for (libelle_groupe,) in fetch_groupes_competence(conn, code_metier):
        content += write_competences_groupe(conn, code_metier, libelle_groupe)

    with open(metier_file, "w", encoding="utf-8") as f:
        f.write(content)

    return metier_file


def write_metiers(famille_dir: str, conn: duckdb.DuckDBPyConnection, famille_id: str) -> None:
    """Écrit toutes les pages métiers d'une famille."""
    for index_metier, (code_metier, nom_metier) in enumerate(fetch_metiers(conn, famille_id), start=1):
        write_metier(famille_dir, conn, index_metier, code_metier, nom_metier)


def write_familles_metiers(site_dir: str, conn: duckdb.DuckDBPyConnection) -> str:
    """Génère l'arborescence familles métiers -> métiers.

    Chaque famille métier devient une catégorie Hugo, et chaque métier actif
    devient une page enfant contenant ses groupes de compétences.
    """
    familles_dir = os.path.join(site_dir, "content", "familles-metiers")
    os.makedirs(familles_dir, exist_ok=True)

    familles_index = os.path.join(familles_dir, "_index.md")
    with open(familles_index, "w", encoding="utf-8") as f:
        f.write("""+++
title = "Familles métiers"
weight = 3

+++

""")

    familles = fetch_familles(conn)

    # Une famille = une section Hugo/Relearn.
    for index_famille, (famille_id, libelle_famille) in enumerate(familles, start=1):
        famille_dir = os.path.join(familles_dir, famille_id)
        os.makedirs(famille_dir, exist_ok=True)
        famille_index = os.path.join(famille_dir, "_index.md")
        with open(famille_index, "w", encoding="utf-8") as f:
            f.write(f"""+++
title = {toml_string(libelle_famille.capitalize())}
weight = {index_famille}

+++

""")

        write_metiers(famille_dir, conn, famille_id)

    return familles_index


def write_document(site_dir: str, conn: duckdb.DuckDBPyConnection) -> None:
    """Génère toutes les pages Markdown du site Hugo."""
    write_home(site_dir)
    write_introduction(site_dir)
    write_niveaux_competence(site_dir)
    write_familles_metiers(site_dir, conn)


def main() -> None:
    """Point d'entrée du script."""
    conn = duckdb.connect(DUCK_DB)
    try:
        write_document(SITE_DIR, conn)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
