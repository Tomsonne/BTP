# Dictionnaire des données

50 tables proposées ; les tables E1/E2 ne sont pas à déployer avant leur lot.

Toutes les tables ont `id uuid NOT NULL` et `created_at timestamptz NOT NULL`. Tables privées : `tenant_id uuid NOT NULL`, PK `(tenant_id,id)`. Tables globales : PK `id`. `calendar_reservations` est globale mais privée à un service interne, avec tenant d’origine et unique `(tenant_id,id)`.

Chaque FK privée reprend tenant_id. Les UUID des exemples sont symboliques, à remplacer par fixtures. Les montants sont en EUR HT sauf mention ; les quantités utilisent l’unité explicitement liée. Les JSON sont des contrats versionnés à valider côté serveur.

Les contraintes inter-objets (états, correspondance client/besoin/devis, appartenance du contact, PDF/version exacte, facture jamais impliquée) sont vérifiées par commandes transactionnelles ; le SQL ne prétend pas toutes les implémenter. Aucune suppression cascade sur l’historique accepté.

## accounts — global

Compte authentifié indépendant des entreprises

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| email | text | non | Email normalisé unique | Unique email | pilote@example.test |
| password_hash | text | non | Hash robuste ; jamais retourné | Validation métier | hash Argon2id |
| state | text | non | Valeur contrôlée : ACTIF, DESACTIVE | state IN ('ACTIF','DESACTIVE') | ACTIF |
| auth_epoch | integer | non | Révocation globale des sessions | Validation métier | 1 |

## sessions — global

Session authentifiée ; sélection tenant recontrôlée à chaque requête

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| account_id | uuid | non | Compte connecté | FK accounts globale | UUID de accounts |
| token_hash | text | non | Empreinte jeton opaque ; secret uniquement en cookie | Unique token_hash | 64 caractères |
| account_auth_epoch | integer | non | Epoch compte lors de création | Validation métier | 1 |
| expires_at | timestamptz | non | Expiration absolue | Validation métier | 2026-10-01T20:00:00Z |
| revoked_at | timestamptz | oui | Révocation | Validation métier | 2026-10-01T20:00:00Z |

## tenants — global

Entreprise SaaS

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| name | text | non | Nom entreprise | Validation métier | Peinture Exemple |
| currency | text | non | Devise MVP unique | Validation métier | EUR |
| pricing_policy | jsonb | non | Politique de prix versionnée à copier dans les devis | Validation métier | {"schema_version":1,"mode":"MAJORATION","rate":"0.25"} |
| ai_monthly_budget | numeric(18,2) | non | Plafond dépenses IA en EUR | Validation métier | 20.00 |
| state | text | non | Valeur contrôlée : ACTIF, SUSPENDU, ARCHIVE | state IN ('ACTIF','SUSPENDU','ARCHIVE') | ACTIF |

## units — global

Unités autorisées et dimensions

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| code | text | non | Code normalisé | Unique code | m2 |
| dimension | text | non | Dimension physique | Validation métier | SURFACE |
| factor_to_base | numeric(18,6) | non | Facteur pour même dimension | factor_to_base > 0 | 1 |

## knowledge_releases — global

Corpus/règles communes autorisés ; aucun tarif privé

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| version | text | non | Identifiant publication | Unique version | peinture-1.0 |
| state | text | non | Valeur contrôlée : CANDIDATE, APPROUVEE, PUBLIEE, RETIREE | state IN ('CANDIDATE','APPROUVEE','PUBLIEE','RETIREE') | CANDIDATE |
| manifest | jsonb | non | Sources/licences/hashes/approbateurs et critères | Validation métier | {"schema_version":1,"sources":[]} |
| hash | text | non | SHA256 du contenu | Validation métier | 64 caractères hex |

## memberships — M

Lien compte entreprise

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| account_id | uuid | non | Compte membre | FK accounts globale ; Unique account_id | UUID de accounts |
| state | text | non | Valeur contrôlée : ACTIF, REVOQUE | state IN ('ACTIF','REVOQUE') | ACTIF |
| auth_epoch | integer | non | Révocation dans tenant | Validation métier | 1 |

## membership_roles — M

Attribution de rôle par appartenance

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| membership_id | uuid | non | Appartenance | FK memberships avec tenant ; Unique membership_id,role | UUID de memberships |
| role | text | non | Valeur contrôlée : AE, DV, CH, EM | role IN ('AE','DV','CH','EM') ; Unique membership_id,role | AE |
| permissions | jsonb | non | Permissions déléguées explicites | Validation métier | ["quote.validate"] |

## invitations — M

Invitation employé à durée limitée

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| email | text | non | Destinataire vérifié | Validation métier | employe@example.test |
| token_hash | text | non | SHA256 jeton, pas le secret | Unique token_hash | 64 caractères |
| expires_at | timestamptz | non | Expiration | Validation métier | 2026-10-01T20:00:00Z |
| used_at | timestamptz | oui | Consommation unique | Validation métier | 2026-10-01T20:00:00Z |
| roles | jsonb | non | Rôles approuvés par AE | Validation métier | ["DV"] |

## clients — M

Bénéficiaire du devis ou chantier

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| name | text | non | Nom bénéficiaire | Validation métier | Client Exemple |
| details | jsonb | non | Coordonnées minimisées | Validation métier | {"schema_version":1,"address":"adresse fictive"} |
| archived_at | timestamptz | oui | Archivage | Validation métier | 2026-10-01T20:00:00Z |

## client_contacts — M

Contact destinataire et futur accès portail

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| client_id | uuid | non | Client lié | FK clients avec tenant | UUID de clients |
| email | text | non | Email vérifié pour envoi | Validation métier | client@example.test |
| name | text | non | Nom affiché | Validation métier | Contact Exemple |

## files — M

Fichier privé scanné ; son chemin seul ne donne aucun droit

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| object_key | text | non | Clé objet inclut tenant | Unique object_key | tenant-uuid/files/random |
| mime_type | text | non | Type réel validé | Validation métier | application/pdf |
| bytes | bigint | non | Taille en octets | bytes >= 0 | 1024 |
| sha256 | text | non | Hash fichier | Validation métier | 64 caractères |
| state | text | non | Valeur contrôlée : QUARANTAINE, DISPONIBLE, REJETE, PURGE | state IN ('QUARANTAINE','DISPONIBLE','REJETE','PURGE') | QUARANTAINE |
| uploaded_by | uuid | non | Auteur | FK accounts globale | UUID de accounts |
| purge_after | timestamptz | oui | Date purge définie par politique | Validation métier | 2026-10-01T20:00:00Z |

## catalog_imports — M

Staging et confirmation de catalogue

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| file_id | uuid | non | XLSX source | FK files avec tenant | UUID de files |
| state | text | non | Valeur contrôlée : EN_ATTENTE, A_CORRIGER, PRET, CONFIRME, ECHEC | state IN ('EN_ATTENTE','A_CORRIGER','PRET','CONFIRME','ECHEC') | EN_ATTENTE |
| mapping | jsonb | non | Colonnes, formats et unités | Validation métier | {"reference":"A","price":"C"} |
| report | jsonb | non | Erreurs et exclusions explicites | Validation métier | {"rows_valid":98,"rows_excluded":2} |
| preview_hash | text | non | Empreinte preview et mapping | Validation métier | 64 caractères |
| base_revision | integer | non | Révision catalogue avant import | Validation métier | 1 |

## catalog_revisions — M

Publication atomique catalogue

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| number | integer | non | Numéro monotone par tenant | number > 0 ; Unique number | 2 |
| import_id | uuid | oui | Source import ou manuel | FK catalog_imports avec tenant | UUID de catalog_imports |
| hash | text | non | Hash manifeste catalogue | Validation métier | 64 caractères |

## resources — M

Matériau, main-d’œuvre, équipement ou frais

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| reference | text | non | Référence entreprise stable | Unique reference | MAT-PEINT-01 |
| name | text | non | Libellé | Validation métier | Peinture blanche |
| kind | text | non | Valeur contrôlée : MATERIAU, MAIN_OEUVRE, EQUIPEMENT, FRAIS | kind IN ('MATERIAU','MAIN_OEUVRE','EQUIPEMENT','FRAIS') | MATERIAU |
| unit_id | uuid | non | Unité de coût/consommation | FK units globale | UUID de units |
| pack_size | numeric(18,6) | oui | Quantité par emballage dans unité de ressource | pack_size > 0 | 5 |
| archived_at | timestamptz | oui | Archivage | Validation métier | 2026-10-01T20:00:00Z |

## resource_prices — M

Historique des prix par publication

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| resource_id | uuid | non | Ressource | FK resources avec tenant ; Unique resource_id,catalog_revision_id | UUID de resources |
| catalog_revision_id | uuid | non | Publication | FK catalog_revisions avec tenant ; Unique resource_id,catalog_revision_id | UUID de catalog_revisions |
| purchase_unit_price | numeric(18,6) | non | Prix HT EUR par unité de coût | purchase_unit_price >= 0 | 6 |
| currency | text | non | Devise prix | Validation métier | EUR |
| source | jsonb | non | Cellule Excel ou saisie sourcée | Validation métier | {"sheet":"Matériaux","cell":"C2"} |

## works — M

Ouvrage stable, par métier

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| reference | text | non | Référence ouvrage | Unique reference | PEINT-2C |
| trade | text | non | Corps de métier | Validation métier | PEINTURE |
| name | text | non | Nom ouvrage | Validation métier | Peinture intérieure deux couches |

## work_revisions — M

Recette immuable publiée

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| work_id | uuid | non | Ouvrage | FK works avec tenant ; Unique work_id,number | UUID de works |
| number | integer | non | Révision recette | number > 0 ; Unique work_id,number | 1 |
| unit_id | uuid | non | Unité de travail | FK units globale | UUID de units |
| conditions | jsonb | non | Conditions/rendements applicables | Validation métier | {"schema_version":1,"coats":2} |
| hash | text | non | Hash recette | Validation métier | 64 caractères |

## work_components — M

Ressource composant un ouvrage, un niveau au MVP

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| work_revision_id | uuid | non | Recette | FK work_revisions avec tenant | UUID de work_revisions |
| resource_id | uuid | non | Ressource | FK resources avec tenant | UUID de resources |
| quantity_per_unit | numeric(18,6) | non | Unité ressource par unité ouvrage | quantity_per_unit > 0 | 0.2 |
| loss_rate | numeric(9,6) | non | Perte appliquée au consommable ; fraction, pas pourcentage entier | loss_rate >= 0 AND loss_rate < 1 | 0.1 |
| basis | jsonb | non | Portée couche/rendement et conditionnement | Validation métier | {"covers_all_coats":true} |

## requirements — M

Besoin agrégé pour un client

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| client_id | uuid | non | Bénéficiaire | FK clients avec tenant | UUID de clients |
| title | text | non | Nom projet | Validation métier | Peinture salon |
| current_revision | integer | non | Révision courante | Validation métier | 1 |

## requirement_revisions — M

Snapshot immuable du besoin et des réponses

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| requirement_id | uuid | non | Besoin | FK requirements avec tenant ; Unique requirement_id,number | UUID de requirements |
| number | integer | non | Numéro révision | number > 0 ; Unique requirement_id,number | 1 |
| payload | jsonb | non | Faits, contraintes, réponses sourcées | Validation métier | {"schema_version":1,"surface_m2":"40"} |
| hash | text | non | Hash entrée | Validation métier | 64 caractères |
| created_by | uuid | non | Auteur | FK accounts globale | UUID de accounts |

## requirement_files — M

Pièces d’une révision de besoin

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| requirement_revision_id | uuid | non | Révision | FK requirement_revisions avec tenant ; Unique requirement_revision_id,file_id | UUID de requirement_revisions |
| file_id | uuid | non | Pièce autorisée | FK files avec tenant ; Unique requirement_revision_id,file_id | UUID de files |

## quotes — M

Agrégat devis et pointeurs métier

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| requirement_id | uuid | non | Besoin associé | FK requirements avec tenant | UUID de requirements |
| reference | text | non | Référence commerciale unique dans tenant | Unique reference | DEV-2026-001 |
| draft_version_id | uuid | oui | Brouillon courant | FK quote_versions avec tenant | UUID de quote_versions |
| active_offer_version_id | uuid | oui | Offre envoyée encore active | FK quote_versions avec tenant | UUID de quote_versions |
| accepted_version_id | uuid | oui | Version acceptée une seule fois | FK quote_versions avec tenant | UUID de quote_versions |
| archived_at | timestamptz | oui | Archivage | Validation métier | 2026-10-01T20:00:00Z |

## quote_versions — M

Version commerciale ; contenu figé dès VALIDE

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| quote_id | uuid | non | Devis parent | FK quotes avec tenant ; Unique quote_id,number ; Unique quote_id,id | UUID de quotes |
| requirement_revision_id | uuid | non | Besoin source | FK requirement_revisions avec tenant | UUID de requirement_revisions |
| number | integer | non | Numéro commercial | number > 0 ; Unique quote_id,number | 1 |
| edit_revision | integer | non | Révision optimiste du brouillon | edit_revision > 0 | 1 |
| state | text | non | Valeur contrôlée : BROUILLON, EN_REVUE, VALIDE, ENVOYE, ACCEPTE, REFUSE, EXPIRE, REMPLACE, ABANDONNE | state IN ('BROUILLON','EN_REVUE','VALIDE','ENVOYE','ACCEPTE','REFUSE','EXPIRE','REMPLACE','ABANDONNE') | BROUILLON |
| currency | text | non | Devise | Validation métier | EUR |
| pricing_snapshot | jsonb | non | Paramètres/recettes/taxes/sources versionnés | Validation métier | {"schema_version":1,"mode":"MAJORATION"} |
| total_ht | numeric(18,2) | non | Vente hors taxes EUR | Validation métier | 302.50 |
| total_tax | numeric(18,2) | non | Taxe par groupe EUR | Validation métier | 60.50 |
| total_ttc | numeric(18,2) | non | TTC EUR | Validation métier | 363.00 |
| content_hash | text | non | Hash contenu figé ou brouillon | Validation métier | 64 caractères |
| valid_until | timestamptz | non | Échéance offre | Validation métier | 2026-10-01T20:00:00Z |
| frozen_at | timestamptz | oui | Gel après validation | Validation métier | 2026-10-01T20:00:00Z |
| validated_by | uuid | oui | Validateur | FK accounts globale | UUID de accounts |

## quote_lines — M

Poste de vente avec snapshots et provenance

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| quote_version_id | uuid | non | Version | FK quote_versions avec tenant ; Unique quote_version_id,position | UUID de quote_versions |
| position | integer | non | Ordre dans document | position > 0 ; Unique quote_version_id,position | 1 |
| work_revision_id | uuid | oui | Ouvrage origine | FK work_revisions avec tenant | UUID de work_revisions |
| label | text | non | Libellé figé | Validation métier | Peinture deux couches |
| unit_id | uuid | non | Unité vendue | FK units globale | UUID de units |
| quantity | numeric(18,6) | non | Quantité vendue | quantity > 0 | 40 |
| sale_unit_price | numeric(18,6) | non | Prix unitaire vente HT EUR | sale_unit_price >= 0 | 7.5625 |
| cost_unit | numeric(18,6) | non | Coût de revient unitaire EUR | cost_unit >= 0 | 6.05 |
| tax_rate | numeric(9,6) | non | Taux taxe configuré ; fraction, pas pourcentage entier | tax_rate >= 0 AND tax_rate < 1 | 0.2 |
| amount_ht | numeric(18,2) | non | Montant arrondi ligne EUR | Validation métier | 302.50 |
| origin | text | non | Valeur contrôlée : EXPLICITE, ESTIMEE, MANUELLE | origin IN ('EXPLICITE','ESTIMEE','MANUELLE') | EXPLICITE |
| confirmed | boolean | non | Confirmation estimation critique | Validation métier | true |
| provenance | jsonb | non | Sources, hypothèses, confirmations et règle calcul | Validation métier | {"schema_version":1,"page":2,"field":"surface"} |

## line_components — M

Détail analytique non vendu en plus de la ligne

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| quote_line_id | uuid | non | Ligne vendue | FK quote_lines avec tenant | UUID de quote_lines |
| resource_price_id | uuid | oui | Prix origine | FK resource_prices avec tenant | UUID de resource_prices |
| label | text | non | Libellé snapshot | Validation métier | Peinture blanche |
| unit_id | uuid | non | Unité | FK units globale | UUID de units |
| quantity | numeric(18,6) | non | Consommation/achat alloué | quantity >= 0 | 10 |
| purchase_unit_snapshot | numeric(18,6) | non | Prix achat HT EUR | purchase_unit_snapshot >= 0 | 6 |
| facturable | boolean | non | Doit rester false en mode ouvrage agrégé | facturable = false | false |
| allocation | jsonb | non | Pertes, emballage et portée | Validation métier | {"scope":"site","packs":2} |

## quote_decisions — M

Preuve de décision sur une version envoyée

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| quote_version_id | uuid | non | Version précise | FK quote_versions avec tenant ; Unique quote_version_id | UUID de quote_versions |
| decision | text | non | Valeur contrôlée : ACCEPTE, REFUSE | decision IN ('ACCEPTE','REFUSE') | ACCEPTE |
| recorded_by | uuid | non | Compte ayant enregistré | FK accounts globale | UUID de accounts |
| proof_file_id | uuid | oui | Pièce de preuve | FK files avec tenant | UUID de files |
| proof | jsonb | non | Canal, date client, contact et justification | Validation métier | {"channel":"email","contact_id":"uuid"} |
| decided_at | timestamptz | non | Date décision | Validation métier | 2026-10-01T20:00:00Z |

## generation_jobs — M

Traitement durable et sa proposition candidate

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| quote_id | uuid | non | Devis cible | FK quotes avec tenant | UUID de quotes |
| requirement_revision_id | uuid | non | Entrée immuable | FK requirement_revisions avec tenant | UUID de requirement_revisions |
| base_version_id | uuid | oui | Brouillon à préserver | FK quote_versions avec tenant | UUID de quote_versions |
| base_edit_revision | integer | non | Révision d’édition au lancement | Validation métier | 1 |
| catalog_revision_id | uuid | non | Catalogue utilisé | FK catalog_revisions avec tenant | UUID de catalog_revisions |
| knowledge_release_id | uuid | non | Règles communes | FK knowledge_releases globale | UUID de knowledge_releases |
| input_snapshot | jsonb | non | Contenu complet minimisé / configurations / modèle | Validation métier | {"schema_version":1,"prompt_version":"1"} |
| input_hash | text | non | Empreinte entrée | Validation métier | 64 caractères |
| state | text | non | Valeur contrôlée : EN_ATTENTE, EN_COURS, A_REPRENDRE, REUSSI, OBSOLETE, ECHEC, ANNULE | state IN ('EN_ATTENTE','EN_COURS','A_REPRENDRE','REUSSI','OBSOLETE','ECHEC','ANNULE') | EN_ATTENTE |
| attempts | integer | non | Tentatives effectuées | attempts >= 0 AND attempts <= 3 | 0 |
| lease_token | bigint | non | Token croissant de possession | Validation métier | 1 |
| lease_until | timestamptz | oui | Fin lease | Validation métier | 2026-10-01T20:00:00Z |
| next_run_at | timestamptz | non | Prochaine exécution | Validation métier | 2026-10-01T20:00:00Z |
| result | jsonb | non | Proposition, questions, blocages, erreur ; pas un devis | Validation métier | {"schema_version":1,"lines":[],"blockers":[]} |
| requested_by | uuid | non | Acteur demandeur | FK accounts globale | UUID de accounts |

## idempotency_keys — M

Déduplication de commandes par tenant/acteur/opération

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| account_id | uuid | non | Acteur | FK accounts globale ; Unique account_id,operation,key | UUID de accounts |
| operation | text | non | Nom commande | Unique account_id,operation,key | quote.generate |
| key | text | non | Clé client opaque | Unique account_id,operation,key | UUID client |
| request_hash | text | non | Hash contenu commande | Validation métier | 64 caractères |
| response | jsonb | non | Réponse stable, identifiant résultat | Validation métier | {"job_id":"uuid"} |
| expires_at | timestamptz | non | Conservation clé, ≥ durée utile | Validation métier | 2026-10-01T20:00:00Z |

## ai_budget_periods — M

Plafond et réservations pour période UTC

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| period | text | non | Mois UTC | Unique period | 2026-10 |
| limit_eur | numeric(18,2) | non | Plafond | Validation métier | 20 |
| reserved_eur | numeric(18,2) | non | Provision jobs | Validation métier | 2 |
| consumed_eur | numeric(18,2) | non | Coût connu ou provisionné | Validation métier | 3 |

## ai_usage — M

Usage par tentative, y compris issue inconnue

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| job_id | uuid | non | Job | FK generation_jobs avec tenant ; Unique job_id,attempt | UUID de generation_jobs |
| attempt | integer | non | Numéro tentative | attempt > 0 ; Unique job_id,attempt | 1 |
| provider_request_id | text | oui | Identifiant fournisseur si connu | Validation métier | req-example |
| model | text | non | Identifiant exact modèle | Validation métier | modele-configure |
| input_tokens | integer | non | Jetons connus ou 0 si inconnus | input_tokens >= 0 | 1000 |
| output_tokens | integer | non | Jetons connus ou 0 si inconnus | output_tokens >= 0 | 300 |
| cost_eur | numeric(18,2) | non | Coût estimé/mesuré EUR | Validation métier | 0.02 |
| cost_state | text | non | Valeur contrôlée : MESURE, ESTIME, INCONNU | cost_state IN ('MESURE','ESTIME','INCONNU') | MESURE |
| tariff_version | text | non | Tarif daté | Validation métier | tarif-2026-10 |

## sites — E1

Chantier issu d’un devis accepté

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| quote_id | uuid | non | Devis origine | FK quotes avec tenant ; Unique quote_id | UUID de quotes |
| reference_quote_version_id | uuid | non | Version acceptée de référence | FK quote_versions avec tenant | UUID de quote_versions |
| client_id | uuid | non | Bénéficiaire | FK clients avec tenant | UUID de clients |
| state | text | non | Valeur contrôlée : PREPARATION, EN_COURS, SUSPENDU, A_RECEVOIR, RESERVES, RECEPTIONNE, CLOTURE, ANNULE | state IN ('PREPARATION','EN_COURS','SUSPENDU','A_RECEVOIR','RESERVES','RECEPTIONNE','CLOTURE','ANNULE') | PREPARATION |
| baseline_revision | integer | non | Révision contractuelle courante | baseline_revision > 0 | 1 |
| contract_total_ht | numeric(18,2) | non | Devis référence + avenants acceptés EUR | Validation métier | 302.50 |
| archived_at | timestamptz | oui | Archivage | Validation métier | 2026-10-01T20:00:00Z |

## site_access — E1

Accès portail limité à un chantier

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| site_id | uuid | non | Chantier | FK sites avec tenant ; Unique site_id,account_id | UUID de sites |
| account_id | uuid | non | Compte client | FK accounts globale ; Unique site_id,account_id | UUID de accounts |
| contact_id | uuid | oui | Contact justificatif | FK client_contacts avec tenant | UUID de client_contacts |
| state | text | non | Valeur contrôlée : ACTIF, REVOQUE | state IN ('ACTIF','REVOQUE') | ACTIF |

## site_stages — E1

Étape pondérée pour avancement

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| site_id | uuid | non | Chantier | FK sites avec tenant | UUID de sites |
| name | text | non | Nom étape | Validation métier | Préparation support |
| weight | numeric(18,6) | non | Poids positif | weight > 0 | 2 |

## site_tasks — E1

Tâche et description de progression

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| stage_id | uuid | non | Étape | FK site_stages avec tenant | UUID de site_stages |
| description | text | non | Travail à réaliser | Validation métier | Protéger les surfaces |
| progress | numeric(18,6) | non | Fraction de 0 à 1 | progress >= 0 AND progress <= 1 | 0.5 |
| weight | numeric(18,6) | non | Poids tâche | weight > 0 | 1 |
| assigned_membership_id | uuid | oui | Responsable affecté | FK memberships avec tenant | UUID de memberships |

## site_media — E1

Photo et visibilité contrôlée

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| site_id | uuid | non | Chantier | FK sites avec tenant | UUID de sites |
| file_id | uuid | non | Image analysée | FK files avec tenant | UUID de files |
| created_by | uuid | non | Auteur | FK accounts globale | UUID de accounts |
| visibility | text | non | Valeur contrôlée : INTERNE, CLIENT | visibility IN ('INTERNE','CLIENT') | INTERNE |
| taken_at | timestamptz | non | Date capture déclarée | Validation métier | 2026-10-01T20:00:00Z |

## site_messages — E1

Message privé ou publié

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| site_id | uuid | non | Chantier | FK sites avec tenant | UUID de sites |
| author_id | uuid | non | Auteur | FK accounts globale | UUID de accounts |
| body | text | non | Texte sans commande IA | Validation métier | Demande de changement |
| visibility | text | non | Valeur contrôlée : INTERNE, CLIENT | visibility IN ('INTERNE','CLIENT') | INTERNE |

## scope_changes — E1

Changement confirmé avec source et delta

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| site_id | uuid | non | Chantier | FK sites avec tenant ; Unique site_id,reference | UUID de sites |
| reference | text | non | Identifiant de changement dédupliqué | Unique site_id,reference | CHG-001 |
| state | text | non | Valeur contrôlée : SUGGERE, CONFIRME, REJETE, COUVERT | state IN ('SUGGERE','CONFIRME','REJETE','COUVERT') | SUGGERE |
| delta_quantity | numeric(18,6) | non | Écart, peut être négatif | Validation métier | 40 |
| unit_id | uuid | non | Unité | FK units globale | UUID de units |
| evidence | jsonb | non | Origine, poste de référence et justification | Validation métier | {"message_id":"uuid","reason":"40 m2 supplémentaires"} |

## amendments — E1

Avenant pour un changement de périmètre

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| site_id | uuid | non | Chantier | FK sites avec tenant ; Unique site_id,reference | UUID de sites |
| scope_change_id | uuid | non | Changement | FK scope_changes avec tenant ; Unique scope_change_id | UUID de scope_changes |
| reference_quote_version_id | uuid | non | Devis accepté de référence | FK quote_versions avec tenant | UUID de quote_versions |
| reference | text | non | Référence commerciale | Unique site_id,reference | AV-001 |

## amendment_versions — E1

Version avenant et baseline attendue

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| amendment_id | uuid | non | Avenant | FK amendments avec tenant ; Unique amendment_id,number | UUID de amendments |
| number | integer | non | Version commerciale | number > 0 ; Unique amendment_id,number | 1 |
| edit_revision | integer | non | Concurrence édition | Validation métier | 1 |
| baseline_revision | integer | non | Baseline attendue | Validation métier | 1 |
| state | text | non | Valeur contrôlée : BROUILLON, EN_REVUE, VALIDE, ENVOYE, ACCEPTE, REFUSE, EXPIRE, REMPLACE, ABANDONNE | state IN ('BROUILLON','EN_REVUE','VALIDE','ENVOYE','ACCEPTE','REFUSE','EXPIRE','REMPLACE','ABANDONNE') | BROUILLON |
| pricing_snapshot | jsonb | non | Conditions figées de calcul et sources | Validation métier | {"schema_version":1} |
| delta_ht | numeric(18,2) | non | Delta vente HT EUR | Validation métier | 302.50 |
| delta_tax | numeric(18,2) | non | Delta taxe EUR | Validation métier | 60.50 |
| delta_ttc | numeric(18,2) | non | Delta TTC EUR | Validation métier | 363.00 |
| content_hash | text | non | Hash contenu | Validation métier | 64 caractères |
| valid_until | timestamptz | non | Expiration | Validation métier | 2026-10-01T20:00:00Z |
| frozen_at | timestamptz | oui | Gel | Validation métier | 2026-10-01T20:00:00Z |

## amendment_lines — E1

Ligne de delta, suppression possible avec motif

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| amendment_version_id | uuid | non | Version | FK amendment_versions avec tenant ; Unique amendment_version_id,position | UUID de amendment_versions |
| position | integer | non | Ordre | Unique amendment_version_id,position | 1 |
| label | text | non | Libellé | Validation métier | Peinture supplémentaire |
| unit_id | uuid | non | Unité | FK units globale | UUID de units |
| delta_quantity | numeric(18,6) | non | Quantité ajoutée ou retirée | Validation métier | 40 |
| sale_unit_price | numeric(18,6) | non | Vente HT EUR unitaire | sale_unit_price >= 0 | 7.5625 |
| tax_rate | numeric(9,6) | non | Taxe ; fraction, pas pourcentage entier | tax_rate >= 0 AND tax_rate < 1 | 0.2 |
| amount_ht | numeric(18,2) | non | Delta ligne arrondi EUR | Validation métier | 302.50 |
| provenance | jsonb | non | Sources et frais déjà couverts | Validation métier | {"schema_version":1,"source_change":"uuid"} |

## amendment_decisions — E1

Décision sur version avenant

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| amendment_version_id | uuid | non | Version | FK amendment_versions avec tenant ; Unique amendment_version_id | UUID de amendment_versions |
| decision | text | non | Valeur contrôlée : ACCEPTE, REFUSE | decision IN ('ACCEPTE','REFUSE') | ACCEPTE |
| recorded_by | uuid | non | Acteur | FK accounts globale | UUID de accounts |
| proof | jsonb | non | Preuve et date, adaptée au canal | Validation métier | {"channel":"portal"} |
| decided_at | timestamptz | non | Date décision | Validation métier | 2026-10-01T20:00:00Z |

## pdf_documents — M/E1

PDF attaché à exactement une version

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| quote_version_id | uuid | oui | Version devis | FK quote_versions avec tenant | UUID de quote_versions |
| amendment_version_id | uuid | oui | Version avenant | FK amendment_versions avec tenant | UUID de amendment_versions |
| file_id | uuid | non | PDF prêt | FK files avec tenant | UUID de files |
| content_hash | text | non | Hash contenu de la version | Validation métier | 64 caractères |
| pdf_hash | text | non | Hash fichier PDF | Validation métier | 64 caractères |

## deliveries — M/E1

Commande d’envoi avec état distinct du devis

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| quote_version_id | uuid | oui | Version devis | FK quote_versions avec tenant | UUID de quote_versions |
| amendment_version_id | uuid | oui | Version avenant | FK amendment_versions avec tenant | UUID de amendment_versions |
| pdf_document_id | uuid | non | PDF exact | FK pdf_documents avec tenant | UUID de pdf_documents |
| recipient_email | text | non | Destinataire figé/vérifié | Validation métier | client@example.test |
| dedupe_key | text | non | Clé stable de livraison | Unique dedupe_key | delivery-uuid |
| state | text | non | Valeur contrôlée : EN_ATTENTE, EN_COURS, CONFIRME, ECHEC, INCERTAIN | state IN ('EN_ATTENTE','EN_COURS','CONFIRME','ECHEC','INCERTAIN') | EN_ATTENTE |
| provider_id | text | oui | Identifiant prestataire | Validation métier | mail-example |
| authorized_by | uuid | non | Personne qui a cliqué envoyer | FK accounts globale | UUID de accounts |

## outbox — M

Événements transactionnels à transmettre

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| event_key | text | non | Clé unique de l’effet | Unique event_key | quote-version-uuid-send |
| kind | text | non | Type effet | Validation métier | SEND_QUOTE |
| payload | jsonb | non | IDs, version, cible ; pas secret | Validation métier | {"delivery_id":"uuid"} |
| state | text | non | Valeur contrôlée : EN_ATTENTE, EN_COURS, CONFIRME, ECHEC, INCERTAIN | state IN ('EN_ATTENTE','EN_COURS','CONFIRME','ECHEC','INCERTAIN') | EN_ATTENTE |
| attempts | integer | non | Tentatives | Validation métier | 0 |
| lease_token | bigint | non | Token de lease | Validation métier | 1 |
| lease_until | timestamptz | oui | Fin lease | Validation métier | 2026-10-01T20:00:00Z |
| next_run_at | timestamptz | non | Prochaine reprise | Validation métier | 2026-10-01T20:00:00Z |

## audit_events — M

Événement métier append-only

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| actor_id | uuid | oui | Acteur, null si système | FK accounts globale | UUID de accounts |
| action | text | non | Nom action | Validation métier | quote.validated |
| entity_type | text | non | Type objet | Validation métier | quote_version |
| entity_id | uuid | non | ID objet dans tenant ; contrôlé par commande | Validation métier | UUID |
| correlation_id | text | non | Chaîne corrélation | Validation métier | request-uuid |
| details | jsonb | non | Version, empreinte et motif, sans contenu complet | Validation métier | {"number":1} |

## feedback — M/E3

Retour privé et autorisation éventuelle de publication

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| job_id | uuid | oui | Génération | FK generation_jobs avec tenant | UUID de generation_jobs |
| comment | text | non | Correction privée | Validation métier | Poste protection manquant |
| sharing | text | non | Valeur contrôlée : PRIVE, PROPOSE_COMMUN, AUTORISE, REJETE | sharing IN ('PRIVE','PROPOSE_COMMUN','AUTORISE','REJETE') | PRIVE |
| sharing_authorization | jsonb | non | Finalité, acteur habilité, droits et date | Validation métier | {"schema_version":1,"allowed":false} |
| release_id | uuid | oui | Publication approuvée | FK knowledge_releases globale | UUID de knowledge_releases |

## calendar_reservations — internal

Calendrier global privé : aucun accès direct via API tenant

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| tenant_id | uuid | non | Entreprise origine, jamais divulguée aux autres | FK tenants globale ; Unique tenant_id,id | UUID de tenants |
| account_id | uuid | non | Personne | FK accounts globale | UUID de accounts |
| period | tstzrange | non | Intervalle UTC [début, fin) | Validation métier | [2026-10-02T08:00Z,2026-10-02T10:00Z) |
| kind | text | non | Valeur contrôlée : AFFECTATION, ABSENCE | kind IN ('AFFECTATION','ABSENCE') | AFFECTATION |
| active | boolean | non | Réservation bloquante active | Validation métier | true |

## assignments — E2

Détail tenant d’une réservation

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| site_id | uuid | non | Chantier | FK sites avec tenant | UUID de sites |
| membership_id | uuid | non | Employé membre | FK memberships avec tenant | UUID de memberships |
| calendar_reservation_id | uuid | non | Réserve globale du même tenant | FK calendar_reservations avec tenant ; Unique calendar_reservation_id | UUID de calendar_reservations |

## leave_requests — E2

Absence proposée puis approuvée avec réserve

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| membership_id | uuid | non | Membre | FK memberships avec tenant | UUID de memberships |
| period | tstzrange | non | Dates UTC proposées | Validation métier | [2026-10-03T00:00Z,2026-10-04T00:00Z) |
| state | text | non | Valeur contrôlée : DEMANDEE, APPROUVEE, REFUSEE, ANNULEE | state IN ('DEMANDEE','APPROUVEE','REFUSEE','ANNULEE') | DEMANDEE |
| calendar_reservation_id | uuid | oui | Réservation absence | FK calendar_reservations avec tenant | UUID de calendar_reservations |
| approved_by | uuid | oui | Approbateur | FK accounts globale | UUID de accounts |

## time_entries — E2

Temps constaté ; pas de calcul de paie

| Champ | Type | Null ? | Sens / unité | Contraintes / lien | Exemple |
|---|---|---|---|---|---|
| site_id | uuid | non | Chantier | FK sites avec tenant | UUID de sites |
| membership_id | uuid | non | Membre | FK memberships avec tenant | UUID de memberships |
| started_at | timestamptz | non | Début UTC | Validation métier | 2026-10-01T20:00:00Z |
| ended_at | timestamptz | non | Fin UTC | Validation métier | 2026-10-01T20:00:00Z |
| state | text | non | Valeur contrôlée : BROUILLON, SOUMIS, APPROUVE | state IN ('BROUILLON','SOUMIS','APPROUVE') | BROUILLON |
| category | text | non | Catégorie selon politique validée | Validation métier | TRAVAIL |
