# Jeu de données de test

Données **synthétiques**, au format exact des fichiers sources (`data/raw`, `data/processed`).
Utilisées par la CI pour lancer `scripts/check_mpd_conformance.py` sans les vrais jeux de données.

Chaque cas couvert par une règle STAGING est présent au moins une fois :

| Règle | Ligne concernée |
|---|---|
| 1 — `TotalCharges` vide → 0 si `tenure = 0` | `0003-CCCCC` |
| 2 — `customerID` en majuscules | `0001-aaaaa` (feedback) |
| 4 — une ligne d'avis seulement s'il y a un verbatim (ligne écartée) | `0002-bbbbb` (feedback) |
| 5 — sentinelle Census → NULL | zipcode `90003` |

Sans règles STAGING le contrôle doit échouer, avec règles il doit passer : la CI vérifie les deux.
