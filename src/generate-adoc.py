import os
import duckdb

conn = duckdb.connect("dist/ref-metiers-opt-nc.duckdb")

OUTPUT_DIR = "data/output/adoc/"
os.makedirs(OUTPUT_DIR, exist_ok=True)

OUTPUT_FILE = OUTPUT_DIR + "referentiel_metiers.adoc"

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write("= Répertoire des emplois OPT-NC 2025\n")
    f.write(":icons: font\n")

    f.write(":toc:\n")
    f.write(":toc-title: Table des matières\n")
    f.write(":toclevels: 2\n\n")  # génère jusqu'au niveau ==

    # ------------------------------------------------------------------------------------------------------

    f.write("== Introduction\n\n")
    f.write("=== Pourquoi une démarche \"Data\" ?\n\n")
    f.write("L'idée derrière ce projet est simple : \"libérer\" la donnée ! \n\n")
    f.write("À l'origine, le Répertoire des emplois 2025 de l'OPT-NC est un document PDF. C'est un format très classique, mais qui enferme l'information. Nous avons donc voulu transformer ce document en une véritable base de données ouverte et exploitable.\n\n")

    f.write("Concrètement, qu'est-ce qu'on a fait ?\n")
    f.write("Nous avons extrait tout le contenu du PDF original, nous l'avons nettoyé, puis restructuré dans un format texte (Markdown/AsciiDoc). On y a même ajouté des métadonnées pour enrichir l'ensemble. Grâce à une petite chaîne d'outils automatisée, on peut désormais générer à la volée des versions EPUB ou PDF de haute qualité.\n\n")
    f.write("L'objectif ? Prouver que l'utilisation de formats ouverts facilite la vie de tout le monde. Avec ces données structurées, il devient très simple de faire des analyses, d'alimenter nos systèmes d'information, ou même de créer de nouvelles applications.\n\n")
    f.write("D'ailleurs, tout ce travail est transparent et partagé en open source. Vous pouvez retrouver le code et les données directement sur notre dépôt GitHub : https://github.com/adriens/odata-optnc-repertoire-emplois/blob/main/2025nn")

    f.write("[NOTE]\n")
    f.write("====\n")
    f.write("*Petite précision technique :* \n")
    f.write("Bien que nous ayons apporté le plus grand soin à cette conversion pour rester fidèles au contenu d'origine, ce document reste une version \"data\" non officielle. Pour toute démarche purement administrative, le PDF original de l'OPT-NC reste la référence absolue.\n")
    f.write("====\n\n")

    f.write("---\n\n")
    f.write("=== Le mot de la Direction des Ressources Humaines\n\n")
    f.write("Huit ans. C’est le temps qui s'est écoulé depuis la toute première édition de notre répertoire en 2017. Aujourd'hui, je suis particulièrement heureuse de partager avec vous sa nouvelle version.\n\n")
    f.write("En huit ans, l'Office a changé, notre environnement aussi, et nos métiers se sont inévitablement transformés. Cette mise à jour était donc essentielle pour refléter la réalité de notre quotidien.\n\n")
    f.write("Aujourd'hui, ce sont **84 fiches emplois**, réparties en **12 grandes familles professionnelles**, qui ont été redessinées. Pour chacune d'entre elles, vous trouverez une description claire des missions, des responsabilités et des compétences attendues. Au fur et à mesure, nous viendrons même y ajouter de nouvelles informations.\n\n")
    f.write("Mais ce répertoire va bien au-delà d'un simple \"catalogue\" d'emplois. Il représente notre véritable boussole commune pour valoriser nos talents internes actuels, tout en nous préparant aux compétences dont nous aurons besoin demain.\n\n")
    f.write("C'est d'ailleurs exactement pour cela que nous déployons en parallèle la plateforme **GEM**. Cet espace numérique est votre nouvel outil pour faire le point sur vos compétences, mettre en lumière vos atouts, et pourquoi pas, repérer de nouvelles opportunités d'évolution au sein de l'OPT-NC.\n\n")
    f.write("Je tiens à remercier chaleureusement toutes les équipes qui ont donné vie à ce projet. Ce répertoire et la plateforme GEM sont entre vos mains : ce sont d'excellents leviers pour construire votre propre parcours, renforcer vos équipes, et participer à l'avenir de l'OPT-NC.\n\n")
    f.write("_Eloïse NICOLAS, Directrice des Ressources Humaines_\n\n")

    # ------------------------------------------------------------------------------------------------------
    familles = conn.execute("""
        SELECT DISTINCT fm.id_famille_metier, fm.libelle
        FROM famille_metier fm
        JOIN metier m on fm.id_famille_metier = m.id_famille_metier
        ORDER BY m.code_metier
    """).fetchall()

    for id_famille, libelle_famille in familles:
        f.write(f"== {libelle_famille}\n\n")

        metiers = conn.execute("""
           SELECT code_metier, metier_collaborateur
           FROM metier
           WHERE id_famille_metier = ?
           AND metier_actif = true
           ORDER BY code_metier
        """, [id_famille]).fetchall()

        for code_metier, nom_metier in metiers:
            f.write(f"=== {code_metier} — {nom_metier}\n\n")

            # Compétences groupées par groupe
            groupes = conn.execute("""
                SELECT DISTINCT gc.libelle
                FROM metier_competence mc
                JOIN competence c ON mc.code_competence = c.code_competence
                JOIN groupe_competence gc ON c.id_groupe_competence = gc.id_groupe_competence
                WHERE mc.code_metier = ?
                ORDER BY gc.libelle
            """, [code_metier]).fetchall()

            # Savoir, Savoire faire, Savoir être
            for (libelle_groupe,) in groupes:
                f.write(f"==== {libelle_groupe.capitalize()}\n\n")

                match libelle_groupe.lower():
                    case "savoir":
                        f.write(f"TIP: le savoir désigne l'ensemble des connaissances théoriques et techniques acquises par la formation ou l'expérience qui sont indispensables pour comprendre et exercer un métier.\n\n")
                    case "savoir faire":
                        f.write(f"TIP: Le savoir-faire désigne la mise en œuvre pratique des connaissances théoriques et la maîtrise de techniques acquises par l'expérience pour accomplir une tâche.\n\n")
                    case "savoir être":
                        f.write(f"TIP: Le savoir-être désigne les qualités relationnelles et comportementales d'un individu, essentielles pour s'adapter à son environnement de travail et interagir avec les autres.\n\n")


                competences = conn.execute("""
                    SELECT mc.nom_competence, mc.niveau_requis,
                    FROM metier_competence mc
                    JOIN competence c ON mc.code_competence = c.code_competence
                    JOIN groupe_competence gc ON c.id_groupe_competence = gc.id_groupe_competence
                    JOIN niveau_description_competence ndc ON mc.code_competence = ndc.code_competence AND ndc.niveau = CAST(mc.niveau_requis AS INTEGER)
                    WHERE mc.code_metier = ?
                    AND gc.libelle = ?
                    ORDER BY mc.nom_competence ASC
                """, [code_metier, libelle_groupe]).fetchall()

                f.write("|===\n")
                f.write(f"|{libelle_groupe.capitalize()} |Score\n\n")
                for nom_comp, niveau in competences:
                    niveau_str = f"{int(niveau)}/4" if niveau else "-"
                    f.write(f"|{nom_comp} |{niveau_str}\n")
                f.write("|===\n\n")

conn.close()