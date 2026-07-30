# Roadmap — Churn Data Platform · Points d'étape mensuels

> **Cadence** : 1 point / mois, le **dernier jeudi**, **août sauté** (congés).
> **Binôme** : Alexandre Gire · Maëva Rodrigues — encadrant : Vincent.
> **Principe** : entre deux points, on avance ; le point sert à **valider le livrable** et à **lancer le lot suivant**.
> **Réf.** : RNCP38919 N7 · blocs BC01→BC04 · sections du dossier (web-app fil-rouge).
> _Établie le 03/07/2026._

---

## Vue d'ensemble

| # | Date | Phase | Livrable à valider | Blocs / Sections |
|---|------|-------|--------------------|------------------|
| **P1** | **jeu. 30 juil. 2026** | Cadrage & Sources | Contexte figé + rapport des sources | BC01 · 1.1-1.3, 4.1 |
| — | *(août sauté)* | | | |
| **P2** | **jeu. 24 sept. 2026** | Cahier des charges, Veille, SWOT/PESTEL, KPIs | Doc de cadrage complet | BC01 · 2.2-2.5, 2.3 |
| **P3** | **jeu. 29 oct. 2026** | Conception & Archi des données | Architecture cible + MPD (Bronze/Silver/Gold) | BC01/BC02 · 3.1-3.4, 4.2 |
| **P4** | **jeu. 26 nov. 2026** | Ingestion & Pipeline ETL/ELT | Pipeline fonctionnel Bronze→Silver | BC02 · 4.3 |
| **P5** | **jeu. 17 déc. 2026** ⚠️ | Couche Gold & Machine Learning | Modèle + MLflow + drift + SHAP | BC03 · 5.2 |
| **P6** | **jeu. 28 janv. 2027** | Dataviz & API | Dashboard + API sécurisée | BC02/BC03 · 5.1, 6.1 |
| **P7** | **jeu. 25 fév. 2027** | Conteneurisation & CI/CD | Podman/compose + pipeline CI | BC03 · 6.2, 7.1, 8.3 |
| **P8** | **jeu. 25 mars 2027** | Déploiement & Monitoring | Infra + Prometheus/Grafana + alertes | BC03/BC04 · 7.2 |
| **P9** | **jeu. 29 avr. 2027** | Pilotage & Dossier final | Dossier complet + prépa soutenance | BC04 · 8.1-8.2, 9.0-11.0 |
| 🎓 | *2ème année (date programme)* | **Soutenance** | Démo appli en prod + vulgarisation | tous |

⚠️ **P5** : le dernier jeudi de décembre tombe le **31 (réveillon)**. Proposé **jeu. 17 déc.** à la place (ou 24). À trancher ensemble.

---

## Détail par point

### 🟦 P1 — jeu. 30 juillet 2026 · Cadrage & Sources
**Déjà en poche (fait) :** PESTEL v2, dictionnaire de données, MCD/MLD.
**À présenter / valider :**
- [ ] Contexte métier, objectifs, périmètre figés (sections 1.1, 1.2, 1.3)
- [ ] **Rapport des sources de données** (livrable Vincent étape 1) : Kaggle Telco + structure des pages Trustpilot pour le scraping + génération synthétique SDV — avec **exemples de données collectées**
- [ ] Réconciliation des **3 versions du PESTEL** (app / PNG / v2) en une seule
- [ ] Réconciliation du **dictionnaire** (noms de tables app `customers/contracts/...` vs notre modèle)
**À faire avant P2 :** rédiger le cahier des charges + démarrer la veille techno.

### 🟦 P2 — jeu. 24 septembre 2026 · Cahier des charges, Veille, SWOT/PESTEL, KPIs & Roadmap
> _Couvre les étapes 2 & 3 de Vincent (« Deadline Sprint 7 » et « Sprint 9 »)._
**À valider :**
- [ ] **Cahier des charges** rédigé (attendus du projet)
- [ ] **Veille techno & réglementaire** : ≥ 3 solutions comparées → dont **stack open-source vs Dataiku** et **PostgreSQL vs MongoDB** (justifier « pourquoi Mongo alors que la search existe »)
- [ ] **SWOT & PESTEL** finalisés + volet **RSE & accessibilité** (section 2.5)
- [ ] **KPIs** en 3 familles : business / ML / technique, chacun argumenté (2.3)
- [ ] **Roadmap de dev** validée (celle-ci) + indicateurs de suivi
**À faire avant P3 :** figer l'architecture cible + le MPD.

### 🟦 P3 — jeu. 29 octobre 2026 · Conception & Architecture des données
**À valider :**
- [ ] **Architecture cible** : schéma global (sources → Bronze/Silver/Gold → ML → API → front) + flux + **justification de CHAQUE techno** (3.2)
- [ ] **MPD PostgreSQL** en couches **Bronze / Silver / Gold** + rôle de **MongoDB** (enrichissement non structuré)
- [ ] **Définition du MVP** (3.1) + **challenge du MVP** : risques, budget (3.4)
- [ ] Contraintes transverses : RGPD, éthique, biais, sobriété (3.3)
**À faire avant P4 :** coder l'ingestion Bronze→Silver.

### 🟦 P4 — jeu. 26 novembre 2026 · Ingestion & Pipeline ETL/ELT
> _Étape 4 de Vincent (« Semaine projet 2 »)._
**À valider :**
- [ ] **Pipeline fonctionnel** : ingestion Kaggle + **scraping Trustpilot** + génération **SDV** → couche **Bronze**
- [ ] Nettoyage / normalisation → **Silver** (TotalCharges vides, doublons `customerID`, casse)
- [ ] Transformation versionnée avec **dbt** ; orchestration **Prefect**
- [ ] Bases **relationnelle (Postgres)** + **NoSQL (Mongo)** reliées (4.3)
**À faire avant P5 :** construire la couche Gold + features + premier modèle.

### 🟦 P5 — jeu. 17 décembre 2026 · Couche Gold & Machine Learning
> _Étape 5 de Vincent (« Semaine projet 3 »)._
**À valider :**
- [ ] **Couche Gold** : tables analytiques / features prêtes pour le ML
- [ ] **Modèle** XGBoost (score de risque, pas juste binaire) + **explicabilité SHAP**
- [ ] **MLflow** : versioning des modèles & expériences
- [ ] **Détection de dérive** des données (drift)
- [ ] **Segmentation / clustering LTV** (valeur client)
**À faire avant P6 :** exposer le modèle (API) + dashboard.

### 🟦 P6 — jeu. 28 janvier 2027 · Data visualisation & API
> _Début étape 6 de Vincent (« Semaine projet 4 »)._
**À valider :**
- [ ] **Dashboard** (Streamlit) : KPIs + **un cas d'usage concret** (5.1)
- [ ] **API FastAPI** : endpoints (prédiction + requêtes BDD), **sécurité**, doc **Swagger/OpenAPI** (6.1)
**À faire avant P7 :** conteneuriser + CI.

### 🟦 P7 — jeu. 25 février 2027 · Conteneurisation & CI/CD
> _Fin étape 6 / début étape 7 de Vincent._
**À valider :**
- [ ] **Conteneurisation dès le départ** : Podman/Docker + **docker-compose** (micro-services) (6.2)
- [ ] **Pipeline CI** (CD en bonus) — GitHub Actions (7.1)
- [ ] **Stratégie de tests & maintenance** (8.3)
**À faire avant P8 :** déployer + monitorer.

### 🟦 P8 — jeu. 25 mars 2027 · Déploiement & Monitoring
> _Étape 7 de Vincent (« Semaine projet 5 »)._
**À valider :**
- [ ] **Déploiement** de l'infra + nouvelles features en prod
- [ ] **Monitoring** : **Prometheus / Grafana**, logs, **métriques DORA** (7.2)
- [ ] **Alertes** automatiques (Slack / mail) sur incidents et drift
**À faire avant P9 :** finaliser le dossier + roadmap produit.

### 🟦 P9 — jeu. 29 avril 2027 · Pilotage, Dossier final & prépa soutenance
**À valider :**
- [ ] **Roadmap produit** (épics, jalons, post-MVP) (8.1)
- [ ] **Gestion des ressources** : RH, technique, coûts, répartition binôme (8.2)
- [ ] **Conduite du changement** (9.0), **Conclusion & perspectives** (10.0), **Annexes** (11.0)
- [ ] **Dossier complet exporté** (Markdown → Word) via la web-app + relecture croisée
**Puis :** répétitions de la **soutenance** (2ème année).

---

## Format de réunion suggéré (30-45 min)
1. **Revue du livrable** du mois (10 min) — est-ce validé ?
2. **Points bloquants / décisions** (10 min) — ex. Mongo vs Postgres, découpage tables, date P5.
3. **Lancement du lot suivant** (10 min) — qui fait quoi (Alexandre / Maëva).
4. **Mise à jour de la roadmap** (5 min) — cocher, réajuster les dates si dérive.
