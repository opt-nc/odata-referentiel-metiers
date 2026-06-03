import os
import duckdb
from datetime import datetime

conn = duckdb.connect("dist/ref-metiers-opt-nc.duckdb")

OUTPUT_DIR = "data/output/doc/"
OUTPUT_DIR_ABS = os.path.abspath(OUTPUT_DIR)
IMAGES_DIR = os.path.abspath("data/static/assets")
IMAGES_DIR_REL = os.path.relpath(IMAGES_DIR, OUTPUT_DIR_ABS).replace(os.sep, "/")

os.makedirs(OUTPUT_DIR_ABS, exist_ok=True)
OUTPUT_FILE = os.path.join(OUTPUT_DIR_ABS, "referentiel_metiers.adoc")

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write("= Répertoire des emplois\n")
    f.write("OPT - NC\n")
    f.write(":icons: font\n")
    f.write(":icon-set: fas\n")
    f.write(f":imagesdir: {IMAGES_DIR_REL}\n")
    f.write(":notitle:\n\n")

    # --- PAGE DE GARDE ---
    
    f.write('[cols="1,1,1,1", width="80%", frame="none", grid="none", align="center"]\n')

    f.write('|===\n')
    f.write('| | image:doc-assets/cover/technicien.png[width=100%] | image:colors/blue.png[width=100%] | \n')
    f.write('| image:doc-assets/cover/facteur.png[width=100%] | image:colors/yellow.png[width=100%] | image:doc-assets/cover/distribution_lettre.png[width=100%] | \n')
    f.write('| | image:doc-assets/cover/teleconseiller.png[width=100%] | image:colors/blue.png[width=100%] | image:doc-assets/cover/assistant.png[width=100%]\n')
    f.write('| | | image:doc-assets/cover/reseau.png[width=100%] | image:colors/yellow.png[width=100%]\n')
    f.write('| image:colors/blue.png[width=100%] | image:doc-assets/cover/accueil.png[width=100%] | | \n')
    f.write('|===\n\n')

    f.write("{empty} +\n{empty} +\n\n")
    
    f.write('[cols="1,1", frame="none", grid="none", valign="bottom"]\n')
    f.write('|===\n')
    f.write('a| \n')
    f.write('**[.subtitle]#REPERTOIRE DES#** +\n')
    f.write('**[.maintitle]#EMPLOIS#**\n')
    
    f.write('a| image::logo/OPT_NC.png[Logo OPT-NC, width=350, align="right"]\n')
    f.write('|===\n\n')

    f.write('[.text-center]\n')
    f.write('**[.subtitle]#2025#**\n\n')

    f.write('[.text-center]\n')
    f.write(f"_Document généré le {datetime.now().strftime("%d/%m/%Y")}_\n\n")
    
    f.write("<<<\n\n")

    # ------------------------------------------------------------------------------------------------------
    
    f.write("[abstract]\n")
    f.write("== icon:clipboard-list[set=fas, role='blue']  Résumé\n\n")
    f.write("Ce document présente le référentiel des métiers de l'OPT-NC. Il rassemble les familles professionnelles, les fiches emplois et les compétences attendues pour chaque métier.\n")
    f.write("Chaque fiche détaille les compétences associées au poste et indique le niveau de maîtrise requis. Ces niveaux permettent de mieux comprendre les attentes, de se situer dans son parcours professionnel et d'identifier les axes de progression possibles.\n\n")
    f.write("Le référentiel est généré automatiquement à partir de données structurées. Cette approche permet de produire une documentation cohérente, lisible et plus simple à maintenir dans le temps.\n\n")

    # ------------------------------------------------------------------------------------------------------

    f.write("== icon:info-circle[set=fas, role=\"blue\"]  Introduction\n\n")
    f.write("=== icon:cogs[set=fas, role=\"gray\"]  Pourquoi une démarche de documentation automatisée ?\n\n")
    f.write("Ce référentiel a été généré à partir de données structurées afin de produire une documentation claire, homogène et facilement maintenable.\n")
    f.write("L'objectif n'est pas simplement de produire un document final, mais de mettre en place une chaîne reproductible. Les données sont chargées dans une base DuckDB, contrôlées, analysées, puis transformées automatiquement en documentation AsciiDoc et en doc-images.\n\n")

    f.write("Concrètement, qu'est-ce qu'on a fait ?\n")
    f.write("Tout d'abord, on charge les bases de données DuckDB et SQLite avec les scripts SQL.\n")
    f.write("On interroge ensuite la base DuckDB avec un script python pour construire le référentiel des métiers, des familles professionnelles et des compétences associées. Le contenu généré est écrit en AsciiDoc, puis converti en doc-images grâce à Asciidoctor doc-images avec un thème dédié.\n")
    f.write("Cette approche permet de garder une source de données structurée, de produire automatiquement une documentation lisible, et de faciliter les mises à jour lorsque les données ou le modèle évoluent.\n")
    f.write("Le code et les données du projet sont disponibles sur le dépôt GitHub : https://github.com/adriens/odata-referentiel-metiers\n\n")


    f.write("---\n\n")
    f.write("=== icon:comments[set=fas, role=\"lightblue\"]  Le mot de la Direction des Ressources Humaines\n\n")
    f.write("> \"Huit ans. C’est le temps qui s'est écoulé depuis la toute première édition de notre répertoire en 2017. Aujourd'hui, je suis particulièrement heureuse de partager avec vous sa nouvelle version.\n")
    f.write("> En huit ans, l'Office a changé, notre environnement aussi, et nos métiers se sont inévitablement transformés. Cette mise à jour était donc essentielle pour refléter la réalité de notre quotidien.\n")
    f.write("> Aujourd'hui, ce sont **84 fiches emplois**, réparties en **12 grandes familles professionnelles**, qui ont été redessinées. Pour chacune d'entre elles, vous trouverez une description claire des missions, des responsabilités et des compétences attendues. Au fur et à mesure, nous viendrons même y ajouter de nouvelles informations.\n")
    f.write("> Mais ce répertoire va bien au-delà d'un simple \"catalogue\" d'emplois. Il représente notre véritable boussole commune pour valoriser nos talents internes actuels, tout en nous préparant aux compétences dont nous aurons besoin demain.\n")
    f.write("> C'est d'ailleurs exactement pour cela que nous déployons en parallèle la plateforme **GEM**. Cet espace numérique est votre nouvel outil pour faire le point sur vos compétences, mettre en lumière vos atouts, et pourquoi pas, repérer de nouvelles opportunités d'évolution au sein de l'OPT-NC.\n")
    f.write("> Je tiens à remercier chaleureusement toutes les équipes qui ont donné vie à ce projet. Ce répertoire et la plateforme GEM sont entre vos mains : ce sont d'excellents leviers pour construire votre propre parcours, renforcer vos équipes, et participer à l'avenir de l'OPT-NC.\"\n")
    f.write("> -- Eloïse NICOLAS, Directrice des Ressources Humaines\n\n")

    # ------------------------------------------------------------------------------------------------------

    f.write("=== icon:graduation-cap[set=fas, role=\"blue\"]  Niveaux de compétences\n\n")
    f.write("==== icon:list-ul[set=fas, role=\"gray\"]  Description des niveaux de compétences\n\n")
    f.write("Dans chaque fiche emploi du répertoire, un niveau est indiqué pour les compétences attendues. Il permet de mieux comprendre le degré de maîtrise nécessaire pour exercer le poste dans de bonnes conditions.\n")
    f.write("L'échelle comporte quatre niveaux. Elle va des premières notions jusqu'à une maîtrise reconnue. Elle sert de repère commun pour savoir ce qui est attendu, situer son propre niveau et repérer les points à renforcer.\n")
    f.write("Ces niveaux peuvent aussi aider à se préparer dans le cadre d'une mobilité, d'un changement de poste ou d'un projet professionnel.\n\n")

    niveaux = [
        (1, "Notions", "La personne connaît les bases du domaine. Elle peut réaliser des tâches simples, mais elle a encore besoin d'être accompagnée pour avancer avec confiance."),
        (2, "Intermédiaire", "La personne possède une compréhension générale du sujet. Elle peut réaliser les tâches courantes de manière autonome, même si elle doit encore consolider sa pratique et gagner en expérience."),
        (3, "Avancé", "La personne maîtrise bien le domaine, aussi bien dans la théorie que dans la pratique. Son expérience lui permet de gérer seule des situations variées, y compris lorsqu'elles sont plus complexes."),
        (4, "Expert", "La personne est reconnue comme une référence dans son domaine. Elle sait traiter des situations inhabituelles, proposer des solutions adaptées et transmettre ses connaissances aux autres."),
    ]

    for niveau, label, description in niveaux:
        niveau_str = " ".join(
            [f"icon:circle[set=fas,role=\"blue\"]"] * niveau
            + [f"icon:circle[set=far,role=\"gray\"]"] * (4 - niveau)
        )
        f.write(f"==== Niveau {niveau} - {label}  {niveau_str}\n\n")
        f.write(f"{description}\n\n")

    # ------------------------------------------------------------------------------------------------------

    familles = conn.execute("""
        SELECT DISTINCT fm.famille_metier_id, fm.libelle
        FROM famille_metier fm
        JOIN metier m on fm.famille_metier_id = m.famille_metier_id
        ORDER BY m.code_metier
    """).fetchall()

    for famille_id, libelle_famille in familles:
        f.write(f"== {libelle_famille}\n\n")

        metiers = conn.execute("""
           SELECT code_metier, metier_collaborateur
           FROM metier
           WHERE famille_metier_id = ?
           AND metier_actif = true
           ORDER BY code_metier
        """, [famille_id]).fetchall()

        for code_metier, nom_metier in metiers:
            f.write(f"=== icon:id-card[set=fas, role=\"red\"]  `{code_metier}` - {nom_metier}\n\n")

            # Compétences groupées par groupe
            groupes = conn.execute("""
                SELECT DISTINCT gc.libelle
                FROM metier_competence mc
                JOIN competence c ON mc.code_competence = c.code_competence
                JOIN groupe_competence gc ON c.groupe_competence_id = gc.groupe_competence_id
                WHERE mc.code_metier = ?
                ORDER BY gc.libelle
            """, [code_metier]).fetchall()

            # Savoir, Savoire faire, Savoir être
            for (libelle_groupe,) in groupes:
                f.write(f"==== icon:book[set=fas, role=\"brown\"]  {libelle_groupe.capitalize()}\n\n")

                match libelle_groupe.lower():
                    case "savoir":
                        f.write("TIP: _Le savoir regroupe les connaissances théoriques et techniques utiles pour comprendre et exercer un métier._\n\n")
                    case "savoir faire":
                        f.write("TIP: _Le savoir-faire correspond à la capacité de mettre ses connaissances en pratique pour réaliser une activité ou accomplir une tâche._\n\n")
                    case "savoir être":
                        f.write("TIP: _Le savoir-être rassemble les attitudes, comportements et qualités relationnelles qui facilitent l'adaptation au travail et les échanges avec les autres._\n\n")


                competences = conn.execute("""
                    SELECT mc.nom_competence, mc.niveau_requis
                    FROM metier_competence mc
                    JOIN competence c ON mc.code_competence = c.code_competence
                    JOIN groupe_competence gc ON c.groupe_competence_id = gc.groupe_competence_id
                    JOIN niveau_description_competence ndc ON mc.code_competence = ndc.code_competence AND ndc.niveau = CAST(mc.niveau_requis AS INTEGER)
                    WHERE mc.code_metier = ?
                    AND gc.libelle = ?
                    ORDER BY mc.nom_competence ASC
                """, [code_metier, libelle_groupe]).fetchall()

                f.write('[cols="85,^.^15"]\n')
                f.write("|===\n")
                f.write(f"|{libelle_groupe.capitalize()} |Score\n\n")

                max_niveau = 4

                for nom_comp, niveau in competences:
                    if niveau:
                        niveau_int = int(niveau)
                        niveau_str = " ".join(
                           [f"icon:circle[set=fas,role=\"blue\"]"] * niveau_int
                            + ["icon:circle[set=far,role=\"gray\"]"] * (max_niveau - niveau_int)
                        )
                    else:
                        niveau_str = "-"
                    f.write(f"|{nom_comp} |{niveau_str}\n")

                f.write("|===\n\n")

conn.close()