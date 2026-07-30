# MCD — Churn Data Platform

> À coller dans [mermaid.live](https://mermaid.live), draw.io (import Mermaid) ou à prévisualiser dans VS Code.
> `PK` = clé primaire · `FK` = clé étrangère.

## Diagramme entité-association

```mermaid
erDiagram
    ZONE_GEO ||--o{ CLIENT : "localise"
    CLIENT   ||--|| CONTRAT : "souscrit"
    CLIENT   ||--|| SERVICES : "dispose de"
    CLIENT   ||--|| SATISFACTION : "genere"
    CLIENT   ||--o{ FEEDBACK : "emet"

    CLIENT {
        string customerID PK
        string gender
        int    SeniorCitizen
        string Partner
        string Dependents
        string Churn "VARIABLE CIBLE"
        string zipcode FK
    }

    CONTRAT {
        string customerID PK_FK
        int    tenure
        string Contract
        string PaperlessBilling
        string PaymentMethod
        float  MonthlyCharges
        float  TotalCharges
    }

    SERVICES {
        string customerID PK_FK
        string PhoneService
        string MultipleLines
        string InternetService
        string OnlineSecurity
        string OnlineBackup
        string DeviceProtection
        string TechSupport
        string StreamingTV
        string StreamingMovies
    }

    SATISFACTION {
        string customerID PK_FK
        int    nb_appels_support
        int    duree_moy_appel_min
        float  score_satisfaction
        int    nps_score
        string motif_contact_principal
        int    derniere_interaction_jours
        int    incident_facturation
    }

    FEEDBACK {
        int    id_feedback PK
        string customerID FK
        string CustomerFeedback
        int    feedback_length
        float  sentiment
        boolean HasFeedback
    }

    ZONE_GEO {
        string zipcode PK
        int    revenu_median
        float  age_median
        float  densite_population
    }
```

## Cardinalités (lecture métier)

| Relation | Cardinalité | Lecture |
|----------|-------------|---------|
| ZONE_GEO → CLIENT | 1 , N | Une zone géographique regroupe plusieurs clients ; un client appartient à une seule zone (via `zipcode`) |
| CLIENT → CONTRAT | 1 , 1 | Un client possède un et un seul contrat |
| CLIENT → SERVICES | 1 , 1 | Un client dispose d'un seul bloc de services |
| CLIENT → SATISFACTION | 1 , 1 | Un client a une seule fiche de satisfaction agrégée |
| CLIENT → FEEDBACK | 1 , N | Un client peut émettre plusieurs verbatims (0, 1 ou N) |

## MLD (clés — pour le passage en PostgreSQL)

- **client** (<u>customerID</u>, gender, SeniorCitizen, Partner, Dependents, Churn, #zipcode)
- **contrat** (<u>#customerID</u>, tenure, Contract, PaperlessBilling, PaymentMethod, MonthlyCharges, TotalCharges)
- **services** (<u>#customerID</u>, PhoneService, MultipleLines, InternetService, OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport, StreamingTV, StreamingMovies)
- **satisfaction** (<u>#customerID</u>, nb_appels_support, duree_moy_appel_min, score_satisfaction, nps_score, motif_contact_principal, derniere_interaction_jours, incident_facturation)
- **feedback** (<u>id_feedback</u>, #customerID, CustomerFeedback, feedback_length, sentiment, HasFeedback)
- **zone_geo** (<u>zipcode</u>, revenu_median, age_median, densite_population)

<u>souligné</u> = clé primaire · # = clé étrangère
