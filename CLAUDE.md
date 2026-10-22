# 🧩 Artefact FilRouge — Contexte pour Claude

## Contexte du projet Churn Data Platform (rappel)

Projet fil rouge RNCP38919 (Data Engineer, niveau 7), mené en binôme par Maëva Rodrigues et Alexandre Gire. Objectif : prédire le churn de clients télécom via un pipeline data complet, du dataset Kaggle Telco Customer Churn jusqu'à l'exposition d'un modèle ML via API.

**Stack technique retenue :**

- Langage : Python (Poetry pour la gestion des dépendances, environnement WSL Ubuntu-24.04)
- Stockage : PostgreSQL, organisé en quatre couches RAW / STAGING / CORE / MART (voir conventions). JSONB pour la partie semi-structurée (réponse brute de l'API Census). Pas de base NoSQL dédiée : MongoDB a été écarté
- Transformation : dbt
- Orchestration : Apache Airflow (conteneurisé via Docker, pas installé dans le venv Python)
- Machine learning : Scikit-learn / XGBoost, suivi via MLflow
- Exposition : FastAPI (API), Streamlit (dashboard)
- Conteneurisation : Docker (pas Podman)
- CI/CD : GitHub Actions
- Structure de projet : Cookiecutter Data Science v2

**Décisions de référence (elles priment sur tout autre document) :**
- **Seule source du modèle :** telco.csv (Kaggle, 7 043 clients, 26,5 % de churn). Baseline : régression logistique, ROC-AUC 0,845 en validation croisée stratifiée à 5 plis. Aucune section ne doit affirmer que les enrichissements améliorent le modèle.
- **Fuite de cible :** les données de satisfaction et les verbatims ont été générés par IA en connaissant le churn (NPS ≤ 0 prédit le churn à 99,4 %, les prompts LLM contenaient la cible). Ils sont ingérés pour la BI et une démo NLP, mais interdits comme variables du modèle.
- **Snapshot sans horodatage :** aucune affirmation temporelle (« X précède Y de N semaines ») n'est démontrable. Le découpage train/test est aléatoire et stratifié sur le churn.
- **Trustpilot : hors MVP** (validé avec le chef de projet), cité uniquement en perspective.
- **SDV :** génération de lots de nouveaux clients pour la démo de scoring (entraîné sur Telco sans la colonne churn). Satisfaction et feedback ne sont pas régénérés en v1.
- **API Census :** ingestion en v1 proposée, en attente de validation ; jointure et usage dans le modèle en v1.1.
- **Architecture validée :** scoring batch. Le modèle écrit ses scores dans la couche MART, l'API FastAPI les lit, Streamlit consomme l'API. Deux DAG : churn_scoring et churn_training.
- En cas de contradiction entre documents, **le registre des décisions du projet fait foi.**

**Plan officiel du dossier** (24 sections, réparties en 6 étapes techniques + intro/roadmap/conclusion) :

0. Page de garde
1. Introduction & contexte (1.1 Contexte métier, 1.2 Objectifs, 1.3 Périmètre) — BC01
2. Étape 1 – Cadrage (2.1 Discovery, 2.2 Existant, 2.3 KPIs, 2.4 Veille techno/réglementaire, 2.5 SWOT & PESTEL) — BC01
3. Étape 2 – Conception (3.1 MVP, 3.2 Architecture cible, 3.3 Contraintes transverses, 3.4 Challenge du MVP) — BC01/BC02/BC04
4. Étape 3 – Data Engineering (4.1 Sources de données, 4.2 Modélisation, 4.3 Pipeline ETL/ELT) — BC02
5. Étape 4 – Exploitation (5.1 Data visualisation, 5.2 Machine Learning) — BC02/BC03
6. Étape 5 – Mise en production (6.1 API, 6.2 Conteneurisation) — BC03
7. Étape 6 – DevOps (7.1 CI/CD, 7.2 Monitoring) — BC03/BC04
8. Roadmap & pilotage (8.1 Roadmap produit, 8.2 Ressources, 8.3 Tests & maintenance) — BC04
9. Lancement & conduite du changement — BC04
10. Conclusion & perspectives — BC01/BC04
11. Annexes

**Conventions générales du projet :**

- Rédaction toujours en français, niveau Bac+5, vocabulaire technique assumé.
- Format prose structurée avec sous-parties (pas de simples listes à puces pour le corps du texte).
- Diagrammes en SVG ou Mermaid pour les schémas d'architecture.
- Code (Python, SQL, YAML) commenté, prêt à intégrer au dépôt.
- **Messages de commit Git en anglais** (le reste (documentation, échanges) reste en français).
- Couches de données : **RAW / STAGING / CORE / MART**, à utiliser telles quelles (ce sont les noms des schémas PostgreSQL, du code et des contrats de données). Le rattachement au pattern **Medallion** se fait une seule fois, par correspondance : RAW = Bronze, STAGING et CORE = Silver, MART = Gold. Ne jamais présenter Bronze / Silver / Gold comme les noms des couches du projet.
- Le mapping aux blocs RNCP (BC01-BC04) est porté par la structure et les annotations du dossier, jamais mentionné explicitement dans le corps du texte des sections.
- Pas de tirets cadratins (—) dans la rédaction : virgules, points, parenthèses à la place.

## Qu'est-ce que c'est ?

fil-rouge-rncp38919.html est une application autonome (artefact Claude, HTML/CSS/JS pur, sans dépendance externe fonctionnelle) qui sert d'espace de rédaction pour le dossier fil rouge RNCP38919 du projet **Churn Data Platform**. Elle est partagée entre Maëva et Alexandre.

Ce fichier est situé dans claude/artefact/fil-rouge-rncp38919.html sur la branche feature/artefact (branche isolée du reste du code, volontairement sans lien d'historique avec develop).

## Comment l'ouvrir

L'artefact doit être ouvert dans **Claude.ai** (pas juste consulté comme fichier HTML statique dans un navigateur) pour que le stockage persistant fonctionne. Deux façons :

- Le publier depuis une conversation Claude (bouton "Publier"), et ouvrir le lien publié.
- Le coller/uploader dans une conversation Claude qui l'exécute en artefact interactif.

⚠️ Si tu ouvres juste le fichier .html en local dans un navigateur (double-clic), les fonctions de stockage (window.storage) ne fonctionneront pas : c'est une API spécifique aux artefacts Claude, pas un stockage web classique.

## Fonctionnement du stockage

- **Stockage partagé** (shared: true) : toi et Maëva voyez les mêmes données, à condition d'ouvrir le **même artefact publié** (même lien). Si tu "remixes" ou dupliques l'artefact dans ton propre espace, tu obtiens une copie indépendante avec un stockage vide, déconnectée de celle de Maëva.
- **Une seule clé de stockage principale** (filrouge-state) contient tout : projet, sections du dossier, SWOT/PESTEL, dictionnaire de données. C'est un choix délibéré après plusieurs itérations : une architecture avec une clé par section avait été tentée puis abandonnée, car elle dépassait la limite de débit (rate limit) de l'API de stockage au chargement.
  - **Conséquence pratique** : si toi et Maëva éditez la **même section** en même temps, le dernier enregistrement écrase l'autre. Éditer des sections différentes en parallèle ne pose pas de problème.
- **Images** : stockées séparément, une clé par image (`img:<id>`), référencées par leur id dans les métadonnées de chaque section. Limite de 5 Mo par image côté API, ~3,5 Mo appliquée côté app par sécurité.

## Structure de l'app

- **Tableau de bord** : avancement global, couverture des blocs RNCP.
- **Mon projet** : contexte projet (nom, domaine, binôme, stack, problématique).
- **Rédaction dossier** : les 24 sections du plan officiel (voir CLAUDE.md racine du repo), avec pour chacune :
  - un encart "Aide à la rédaction" (quoi couvrir, pièges à éviter, lien avec le livrable attendu),
  - un champ de texte principal,
  - une galerie d'images attachées.
- **SWOT & PESTEL** : grille éditable case par case, avec un bouton pour générer automatiquement des schémas visuels (SVG rasterisé en PNG) et les insérer comme images dans la section 2.5.
- **Dictionnaire de données** : tableau éditable (table, champ, type, description, exemple).
- **Blocs de compétences** : vue de couverture BC01 à BC04 selon les sections rédigées.
- **Export** : trois formats — .md (texte brut), .html (autonome, images incluses), .doc (Word-compatible, généré en HTML avec les balises Microsoft Office, images incluses).

## Pourquoi pas de vrai export .docx natif ?

L'app tourne dans un **iframe sandboxé** de Claude.ai qui bloque le chargement de scripts externes (ex. la librairie docx.js via CDN). L'export .doc contourne ce problème en générant un document HTML avec les métadonnées Microsoft Word (xmlns:o=, xmlns:w=), que Word/LibreOffice ouvrent nativement sans dépendance externe. Ce n'est pas un vrai fichier OOXML : si un .docx strict est nécessaire, ouvrir le .doc dans Word et faire "Enregistrer sous → .docx".

## Conventions de rédaction à respecter

- **Pas de tirets cadratins (—)** dans le texte rédigé : préférer virgules, points, parenthèses.
- **Pas de mention explicite des blocs RNCP (BC01-BC04) dans le corps du texte** des sections : le mapping est déjà porté par la structure et les annotations de l'app.
- Ton professionnel, niveau Bac+5, 300-600 mots par section (indicateur de couleur intégré : vert = dans la cible, orange = proche, rouge = hors cible ou vide).

## Historique des bugs déjà rencontrés (pour éviter de les reproduire)

1. **Migration d'architecture de stockage** : une version antérieure utilisait une clé par section, causant des erreurs Message rate limit exceeded. Corrigé en revenant à une seule clé globale.
2. **Perte de contenu après une réécriture de fichier** : si tu modifies la logique de sauvegarde, vérifie toujours qu'une section déjà rédigée reste lisible après rechargement avant de committer.
3. **Vignettes d'images rognées** : les schémas générés automatiquement (SWOT/PESTEL) utilisent object-fit: contain plutôt que cover, car ce sont des schémas larges et non des photos.

## Autres ressources liées au projet

- Dossier Google Drive du projet (roadmap Obsidian, comparatif technos, etc.)
- Board Whimsical (roadmap visuelle + board de process A1-A11)
- Designs Canva (SWOT, PESTEL en version illustrée)
