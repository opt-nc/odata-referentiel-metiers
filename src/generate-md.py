import argparse
import json
import os
import duckdb

DEFAULT_DUCK_DB = "dist/ref-metiers-opt-nc.duckdb"
DEFAULT_SITE_DIR = "site"
CUSTOM_HEADER_TEMPLATE = "etc/config/hugo/partials/custom-header.html"

# Couleurs sombres reprises de etc/themes/epub-style.css.
DARK_FAMILY_COLORS = {
    "vente-relation-client": "#F06BB8",
    "marketing-et-communication": "#FFB8E2",
    "services-bancaires": "#4DD6E2",
    "activites-postales": "#FFD84D",
    "telecommunications": "#FF6B6E",
    "administration": "#52D68D",
    "ressources-humaines": "#D6A1F0",
    "finances-budget": "#FF9A5C",
    "patrimoine-bati": "#B2D875",
    "logistique": "#A7E5E6",
    "systemes-d-information": "#76B7E8",
    "pilotage": "#FFD0B8",
}

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

HOME_MD = """+++
title = "Référentiel Métiers OPT-NC"
type = "home"

+++

## <i class="fa-fw fas fa-clipboard-list family-color blue"></i> Résumé

Ce document présente le référentiel des métiers de l'OPT-NC. Il rassemble les familles professionnelles, les fiches emplois et les compétences attendues pour chaque métier.

Chaque fiche détaille les compétences associées au poste et indique le niveau de maîtrise requis. Ces niveaux permettent de mieux comprendre les attentes, de se situer dans son parcours professionnel et d'identifier les axes de progression possibles.

Le référentiel est généré automatiquement à partir de données structurées. Cette approche permet de produire une documentation cohérente, lisible et plus simple à maintenir dans le temps.
"""


INTRODUCTION_MD = """+++
title = "INTRODUCTION"
weight = 1

+++

## <i class="fa-fw fas fa-cogs family-color gray"></i> Pourquoi une démarche de documentation automatisée ?

Ce référentiel a été généré à partir de données structurées afin de produire une documentation claire, homogène et facilement maintenable.

L'objectif n'est pas simplement de produire un document final, mais de mettre en place une chaîne reproductible. Les données sont chargées dans une base DuckDB, contrôlées, analysées, puis transformées automatiquement en documentation.

Concrètement, la génération s'appuie sur les scripts du projet pour construire les bases de données, produire les exports et préparer les contenus destinés aux différents formats de publication.

Cette approche permet de garder une source de données structurée, de produire automatiquement une documentation lisible, et de faciliter les mises à jour lorsque les données ou le modèle évoluent.

---

## <i class="fa-fw fas fa-comments family-color blue"></i> Le mot de la Direction des Ressources Humaines

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
title = "NIVEAUX DE COMPÉTENCES"
weight = 2

+++

## <i class="fa-fw fas fa-list-ul family-color gray"></i> Description des niveaux de compétences

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


def toml_list(values: list[str]) -> str:
    """Écrit une liste de textes au format TOML."""
    return "[" + ", ".join(toml_string(value) for value in values) + "]"


def menu_pre(icon: str) -> str:
    """Construit l'icône Font Awesome affichée avant un titre de menu."""
    return toml_string(f"<i class='fa-fw fas fa-{icon}'></i> ")


def texte_cellule_html(value: str) -> str:
    """Prépare un texte pour l'afficher dans une cellule HTML."""
    return " ".join(value.splitlines()).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def role_famille(famille_id: str) -> str:
    """Transforme l'identifiant famille en nom de classe CSS."""
    return famille_id.replace("_", "-") if famille_id else "blue"


def fontawesome_icon(icon_class: str, color_class: str) -> str:
    """Construit une icône Font Awesome avec une classe couleur."""
    return f'<i class="fa-fw {icon_class} family-color {color_class}"></i>'


def niveau_score(niveau: float | int | None, color_class: str = "blue", max_niveau: int = 4) -> str:
    """Convertit un niveau numérique en quatre icônes Font Awesome."""
    if niveau is None:
        return "-"

    niveau_int = int(niveau)
    return " ".join(
        [fontawesome_icon("fas fa-circle", color_class)] * niveau_int
        + [fontawesome_icon("far fa-circle", "gray")] * (max_niveau - niveau_int)
    )


def write_family_color_css(site_dir: str, familles: list[tuple[str, str, str]]) -> str:
    """Écrit la CSS Hugo des couleurs d'icônes par famille, avec variantes claire, sombre et auto."""
    css_file = os.path.join(site_dir, "static", "css", "family-colors.css")
    os.makedirs(os.path.dirname(css_file), exist_ok=True)

    # Mode clair
    content = ":root {\n"
    content += "  --family-color-blue: #1565C0;\n"
    content += "  --family-color-gray: #BDBDBD;\n"

    for famille_id, _libelle_famille, couleur_hex in familles:
        content += f"  --family-color-{role_famille(famille_id)}: {couleur_hex};\n"
    content += "}\n"

    # Mode sombre
    content += "\n:root[data-r-theme-variant='opt-dark-theme'] {\n"
    content += "  --family-color-blue: #76B7E8;\n"
    content += "  --family-color-gray: #D0D0D0;\n"
    for famille_id, _libelle_famille, _couleur_hex in familles:
        famille_class = role_famille(famille_id)
        dark_color = DARK_FAMILY_COLORS.get(famille_class)
        if dark_color:
            content += f"  --family-color-{famille_class}: {dark_color};\n"
    content += "}\n"

    # Mode auto
    content += "\n@media (prefers-color-scheme: dark) {\n"
    content += "  :root[data-r-theme-variant='auto'] {\n"
    content += "    --family-color-blue: #76B7E8;\n"
    content += "    --family-color-gray: #D0D0D0;\n"
    for famille_id, _libelle_famille, _couleur_hex in familles:
        famille_class = role_famille(famille_id)
        dark_color = DARK_FAMILY_COLORS.get(famille_class)
        if dark_color:
            content += f"    --family-color-{famille_class}: {dark_color};\n"
    content += "  }\n"
    content += "}\n\n"

    content += ".family-color.blue { color: var(--family-color-blue); }\n"
    content += ".family-color.gray { color: var(--family-color-gray); }\n"
    for famille_id, _libelle_famille, _couleur_hex in familles:
        famille_class = role_famille(famille_id)
        content += f".family-color.{famille_class} {{ color: var(--family-color-{famille_class}); }}\n"

    with open(css_file, "w", encoding="utf-8") as f:
        f.write(content)

    return css_file


def write_family_tag_data(site_dir: str, familles: list[tuple[str, str, str]]) -> str:
    """Écrit la correspondance entre les tags Hugo et les couleurs de familles."""
    data_file = os.path.join(site_dir, "data", "family_tags.json")
    os.makedirs(os.path.dirname(data_file), exist_ok=True)

    content = {
        "tags": [
            {
                "title": libelle_famille.upper(),
                "class": role_famille(famille_id),
            }
            for famille_id, libelle_famille, _couleur_hex in familles
        ]
    }

    with open(data_file, "w", encoding="utf-8") as f:
        json.dump(content, f, ensure_ascii=False, indent=2)
        f.write("\n")

    return data_file


def write_custom_header_from_template(site_dir: str, familles: list[tuple[str, str, str]]) -> str:
    """Génère le partial Hugo custom-header depuis son template."""
    header_file = os.path.join(site_dir, "layouts", "partials", "custom-header.html")
    os.makedirs(os.path.dirname(header_file), exist_ok=True)

    search_family_rules = ""
    search_family_data = json.dumps(
        [
            {
                "title": libelle_famille.upper(),
                "className": role_famille(famille_id),
            }
            for famille_id, libelle_famille, _couleur_hex in familles
        ],
        ensure_ascii=False,
    )
    for famille_id, _libelle_famille, _couleur_hex in familles:
        famille_class = role_famille(famille_id)
        search_family_rules += (
            f'#R-searchresults > *:has(a[href*="/familles-metiers/{famille_id}/"]) {{\n'
            f"  border-left-color: var(--family-color-{famille_class}) !important;\n"
            "}\n\n"
        )

    with open(CUSTOM_HEADER_TEMPLATE, "r", encoding="utf-8") as f:
        content = f.read()

    content = content.replace("{{SEARCH_FAMILY_RULES}}", search_family_rules.rstrip())
    content = content.replace("{{SEARCH_FAMILY_DATA}}", search_family_data)

    with open(header_file, "w", encoding="utf-8") as f:
        f.write(content)

    return header_file


def write_favicon(site_dir: str) -> str:
    """Utilise le logo OPT-NC comme icône de l'onglet du navigateur."""
    favicon_file = os.path.join(site_dir, "layouts", "partials", "favicon.html")
    os.makedirs(os.path.dirname(favicon_file), exist_ok=True)

    content = """<link rel="icon" href="{{ "assets/logo/OPT_NC_2.png" | relURL }}" type="image/png">
<link rel="apple-touch-icon" href="{{ "assets/logo/OPT_NC_2.png" | relURL }}">
"""

    with open(favicon_file, "w", encoding="utf-8") as f:
        f.write(content)

    return favicon_file


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


def fetch_familles(conn: duckdb.DuckDBPyConnection) -> list[tuple[str, str, str]]:
    """Récupère les familles qui possèdent au moins un métier actif."""
    return conn.execute("""
        SELECT DISTINCT fm.famille_metier_id, fm.libelle, fmc.couleur_hex
        FROM famille_metier fm
        JOIN famille_metier_couleur fmc ON fm.famille_metier_id = fmc.famille_metier_id
        JOIN metier m on fm.famille_metier_id = m.famille_metier_id
        WHERE m.metier_actif = true
        GROUP BY fm.famille_metier_id, fm.libelle, fmc.couleur_hex
        ORDER BY MAX(m.code_metier)
    """).fetchall()


def fetch_metiers(conn: duckdb.DuckDBPyConnection, famille_id: str) -> list[tuple[str, str]]:
    """Récupère les métiers actifs d'une famille."""
    return conn.execute("""
        SELECT code_metier, nom_metier
        FROM metier
        WHERE famille_metier_id = ?
        AND metier_actif = true
        ORDER BY code_metier
    """, [famille_id]).fetchall()


def count_metiers(conn: duckdb.DuckDBPyConnection, famille_id: str) -> int:
    """Compte les métiers actifs d'une famille."""
    return conn.execute("""
        SELECT COUNT(*)
        FROM metier
        WHERE famille_metier_id = ?
        AND metier_actif = true
    """, [famille_id]).fetchone()[0]


def familles_metiers_cards(conn: duckdb.DuckDBPyConnection, familles: list[tuple[str, str, str]]) -> str:
    """Construit les cartes de familles affichées sur la page parent."""
    if not familles:
        return ""

    content = '<div class="familles-family-list">\n'
    for famille_id, libelle_famille, _couleur_hex in familles:
        famille_class = role_famille(famille_id)
        libelle_html = texte_cellule_html(libelle_famille.upper())
        nombre_metiers = count_metiers(conn, famille_id)

        content += f'  <a class="metier-family-card" href="{famille_id}/" style="--family-card-color: var(--family-color-{famille_class});">\n'
        content += '    <div class="metier-family-card-main">\n'
        content += f'      <p class="metier-family-card-title">{libelle_html}</p>\n'
        content += '      <div class="metier-family-card-meta">\n'
        content += f'        <span><i class="fa-fw fas fa-id-card"></i> {nombre_metiers} métiers actifs</span>\n'
        content += "      </div>\n"
        content += "    </div>\n"
        content += '    <span class="metier-family-card-action">Voir la famille <i class="fa-fw fas fa-arrow-right"></i></span>\n'
        content += "  </a>\n"
    content += "</div>\n\n"

    return content


def metiers_famille_cards(metiers: list[tuple[str, str]], famille_class: str, libelle_famille: str) -> str:
    """Construit la liste de cartes affichée sur la page d'une famille métier."""
    if not metiers:
        return ""

    content = f'<div class="metiers-family-list" style="--family-card-color: var(--family-color-{famille_class});">\n'
    for code_metier, nom_metier in metiers:
        code_html = texte_cellule_html(code_metier)
        nom_html = texte_cellule_html(nom_metier)
        famille_html = texte_cellule_html(libelle_famille.upper())
        href = f"{code_metier.lower()}/"

        content += f'  <a class="metier-family-card" href="{href}">\n'
        content += '    <div class="metier-family-card-main">\n'
        content += f'      <p class="metier-family-card-title">{nom_html}</p>\n'
        content += '      <div class="metier-family-card-meta">\n'
        content += f'        <span class="metier-family-card-code"><i class="fa-fw fas fa-barcode"></i> {code_html}</span>\n'
        content += f'        <span><i class="fa-fw fas fa-layer-group"></i> {famille_html}</span>\n'
        content += "      </div>\n"
        content += "    </div>\n"
        content += '    <span class="metier-family-card-action">Voir la fiche complète <i class="fa-fw fas fa-arrow-right"></i></span>\n'
        content += "  </a>\n"
    content += "</div>\n\n"

    return content


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
        SELECT DISTINCT c.nom_competence, mc.niveau_requis
        FROM metier_competence mc
        JOIN competence c ON mc.code_competence = c.code_competence
        JOIN groupe_competence gc ON c.groupe_competence_id = gc.groupe_competence_id
        JOIN niveau_description_competence ndc ON mc.code_competence = ndc.code_competence
        WHERE mc.code_metier = ?
        AND gc.libelle = ?
        ORDER BY c.nom_competence ASC
    """, [code_metier, libelle_groupe]).fetchall()


def write_competences_groupe(conn: duckdb.DuckDBPyConnection, code_metier: str, libelle_groupe: str, famille_class: str) -> str:
    """Construit la section Markdown d'un groupe de compétences."""
    content = f"## {fontawesome_icon('fas fa-book', famille_class)} {libelle_groupe.capitalize()}\n\n"

    description = GROUPE_DESCRIPTIONS.get(libelle_groupe.lower())
    if description:
        content += '{{% notice style="tip" color="#FBC02D" title=" " %}}\n'
        content += f"_{description}_\n"
        content += "{{% /notice %}}\n\n"

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
        content += f"      <td>{texte_cellule_html(nom_competence)}</td>\n"
        content += f'      <td style="text-align: center;">{niveau_score(niveau, famille_class)}</td>\n'
        content += "    </tr>\n"

    content += "  </tbody>\n"
    content += "</table>\n"

    return content + "\n"


def write_metier(famille_dir: str, conn: duckdb.DuckDBPyConnection, index_metier: int, code_metier: str, nom_metier: str, famille_id: str, famille_class: str, libelle_famille: str) -> str:
    """Écrit la page Markdown d'un métier."""
    metier_dir = os.path.join(famille_dir, code_metier.lower())
    os.makedirs(metier_dir, exist_ok=True)
    metier_file = os.path.join(metier_dir, "_index.md")
    metier_keywords = [code_metier, nom_metier, libelle_famille.upper()]

    content = f"""+++
title = {toml_string(f"{code_metier} - {nom_metier}")}
weight = {index_metier}
collapsibleMenu = true
tags = {toml_list([libelle_famille.upper()])}
keywords = {toml_list(metier_keywords)}

+++

<span class="a11y-only">Code métier : {code_metier}</span>

<p class="taxonomy-backlink">
  <a href="/familles-metiers/{famille_id}/"><i class="fa-fw fas fa-arrow-left"></i> Retour à la famille {libelle_famille.upper()}</a>
</p>

"""

    # Un groupe de compétences = une section dans la page métier.
    for (libelle_groupe,) in fetch_groupes_competence(conn, code_metier):
        content += write_competences_groupe(conn, code_metier, libelle_groupe, famille_class)

    with open(metier_file, "w", encoding="utf-8") as f:
        f.write(content)

    return metier_file


def write_metiers(famille_dir: str, conn: duckdb.DuckDBPyConnection, famille_id: str, famille_class: str, libelle_famille: str) -> None:
    """Écrit toutes les pages métiers d'une famille."""
    for index_metier, (code_metier, nom_metier) in enumerate(fetch_metiers(conn, famille_id), start=1):
        write_metier(famille_dir, conn, index_metier, code_metier, nom_metier, famille_id, famille_class, libelle_famille)


def write_familles_metiers(site_dir: str, conn: duckdb.DuckDBPyConnection) -> str:
    """Génère l'arborescence familles métiers -> métiers.

    Chaque famille métier devient une catégorie Hugo, et chaque métier actif
    devient une page enfant contenant ses groupes de compétences.
    """
    familles_dir = os.path.join(site_dir, "content", "familles-metiers")
    os.makedirs(familles_dir, exist_ok=True)

    familles = fetch_familles(conn)
    write_family_color_css(site_dir, familles)
    write_family_tag_data(site_dir, familles)
    write_custom_header_from_template(site_dir, familles)
    write_favicon(site_dir)

    familles_index = os.path.join(familles_dir, "_index.md")
    with open(familles_index, "w", encoding="utf-8") as f:
        f.write("""+++
title = "FAMILLES MÉTIERS"
weight = 3
collapsibleMenu = true

+++

""")
        f.write("Cette page regroupe les familles professionnelles du référentiel. Sélectionnez une famille pour consulter les métiers associés.\n\n")
        f.write(familles_metiers_cards(conn, familles))

    # Une famille = une section Hugo/Relearn.
    for index_famille, (famille_id, libelle_famille, _couleur_hex) in enumerate(familles, start=1):
        famille_class = role_famille(famille_id)
        famille_dir = os.path.join(familles_dir, famille_id)
        os.makedirs(famille_dir, exist_ok=True)
        famille_index = os.path.join(famille_dir, "_index.md")
        metiers = fetch_metiers(conn, famille_id)
        with open(famille_index, "w", encoding="utf-8") as f:
            f.write(f"""+++
title = {toml_string(libelle_famille.upper())}
weight = {index_famille}
collapsibleMenu = true
alwaysopen = false

+++

""")
            f.write("""<p class="taxonomy-backlink">
  <a href="/familles-metiers/"><i class="fa-fw fas fa-arrow-left"></i> Retour aux familles métiers</a>
</p>

""")
            f.write(metiers_famille_cards(metiers, famille_class, libelle_famille))

        write_metiers(famille_dir, conn, famille_id, famille_class, libelle_famille)

    return familles_index


def write_document(site_dir: str, conn: duckdb.DuckDBPyConnection) -> None:
    """Génère toutes les pages Markdown du site Hugo."""
    write_home(site_dir)
    write_introduction(site_dir)
    write_niveaux_competence(site_dir)
    write_familles_metiers(site_dir, conn)


def parse_args():
    """Lit les paramètres du générateur Hugo Markdown."""
    parser = argparse.ArgumentParser(description="Génère les pages Markdown du site Hugo.")
    parser.add_argument("--duckdb", default=DEFAULT_DUCK_DB, help="Chemin vers la base DuckDB source.")
    parser.add_argument("--site-dir", default=DEFAULT_SITE_DIR, help="Dossier du site Hugo à alimenter.")
    return parser.parse_args()


def main() -> None:
    """Point d'entrée du script."""
    args = parse_args()

    conn = duckdb.connect(args.duckdb)
    try:
        write_document(args.site_dir, conn)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
