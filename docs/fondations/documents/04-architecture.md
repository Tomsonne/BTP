# Architecture cible et contrats

## Architecture proposée
Monorepo TypeScript : `apps/web` (React), `apps/api` (Node.js avec framework HTTP stable à choisir), `apps/worker`, `packages/domain`, `packages/contracts`, `packages/pricing`, `packages/knowledge`, `infra`, `tests`. API et worker exécutent le même monolithe modulaire dans deux processus. PostgreSQL contient états, snapshots, file durable de jobs et outbox. Stockage objet privé pour originaux et PDF. Aucun Redis ni bus distribué obligatoire au MVP ; extraction par lease DB et `SKIP LOCKED`, sans garder de verrou pendant les appels externes.

Modules : Identité/Accès ; Clients/Besoins ; Catalogue/Imports ; Devis/Versions ; Chiffrage pur ; Orchestration IA ; Documents/Envois ; Audit/Usage ; puis Chantiers/Avenants/Planning. Un module appelle un service public d'un autre module, jamais ses tables de manière ad hoc. Les transactions multi-modules restent locales au monolithe. Ajouter des microservices seulement si volume, contraintes d'exploitation ou responsabilité d'équipe le justifient.

## Contrats API proposés (non implémentés)
| Commande | Préconditions et résultat |
|---|---|
| `POST /tenants/{t}/catalog-imports` | Appartenance vérifiée, fichier en quarantaine ; 202 + import_id. |
| `POST /catalog-imports/{id}/confirm` | Idempotency-Key, preview_hash, revision catalogue ; 200/202 ; 409 si prévisualisation périmée. |
| `POST /requirements/{id}/revisions` | If-Match ; crée snapshot après contrôle des pièces ; 201, ou 409. |
| `POST /quotes/{id}/generations` | Idempotency-Key + input_revision ; budget réservé ; 202 + job_id et Location. |
| `GET /generation-jobs/{id}` | Portée tenant ; état technique, questions, alertes, proposition candidate. |
| `POST /quotes/{id}/versions/from-proposal` | If-Match + job_id REUSSI et non obsolète ; transaction + version_id ; 409 sinon. |
| `PATCH /quote-versions/{id}` | BROUILLON + If-Match ; validation syntaxique et recalcul déterministe ; nouvelle edit_revision. |
| `POST /quote-versions/{id}/review` | BROUILLON + permission ; EN_REVUE, blocages visibles. |
| `POST /quote-versions/{id}/validate` | EN_REVUE + If-Match + permission ; zéro blocage ; fige snapshot et crée demande PDF durable. |
| `POST /quote-versions/{id}/send` | VALIDE + PDF prêt + permission + action explicite + clé ; 202, delivery_id ; état reste VALIDE jusqu'à confirmation. |
| `POST /quote-versions/{id}/decisions` | ENVOYE active + preuve + permission ; verrou sur devis ; 201, sinon 409/422. |
| `POST /sites/from-quote` | Devis accepté + clé ; un site par devis ; 201 ou résultat déjà créé. |
| `POST /sites/{id}/scope-changes` | E1, source et quantités documentées, accès site. |
| `POST /amendment-versions/{id}/accept` | E1, état ENVOYE + baseline attendue + preuve ; verrou site puis avenant ; 409 si rebase requis. |

Erreurs : 401 non authentifié ; 403 permission insuffisante dans espace accessible ; 404 pour objet d'un autre tenant (pas de fuite d'existence) ; 409 concurrence/idempotence/baseline ; 413 limite fichier ; 415 type ; 422 données métier incomplètes ; 429 quota/rate limit ; 503 prestataire indisponible. Les erreurs DB de FK/unicité deviennent des erreurs métier neutres sans identifiant tiers.

## Génération durable et concurrence
Clé idempotente = tenant, acteur, opération, clé client ; empreinte du corps incluse. Un clic répété réutilise le job. Un job contient révision besoin, hash snapshot, version catalogue, règles, prompt, modèle et politique de prix. Il réserve un plafond de coût avant appel. Chaque tentative a son propre numéro et identifiant fournisseur lorsqu'il existe.

Worker prend une lease courte et un `lease_token` monotone ; heartbeat, puis exécute hors transaction. La finalisation exige le même token : un ancien worker ne peut pas publier après reprise par un autre. Snapshot courant changé → OBSOLETE ; résultat reste inspectable, application interdite. Résultat structuré invalide → ECHEC avec diagnostic sans prix par défaut. Résultat structurel valide avec champs manquants → REUSSI mais bloqueurs métier ; les questions sont répondues dans une nouvelle révision avant nouvelle génération. Limite proposée : 3 tentatives sur timeout, 5xx ou 429 compatible avec échéance ; délai maximum total 10 min, appel 90 s, backoff exponentiel avec jitter. 401/403 fournisseur ou erreur de schéma persistante ne sont pas réessayés automatiquement.

Un timeout ambigu peut avoir été facturé. Ne pas promettre un appel IA exactement une fois : conserver usage inconnu, plafond par tentative, et rapprochement fournisseur. Réservation plafonne les nouvelles tentatives ; ne libérer que le coût non consommé connu ou provisionné. `SUCCES` n'existe pas : état terminal canonique `REUSSI`.

## Isolation et identités
Compte global ; `(tenant_id, account_id)` unique pour appartenance. Toute table privée possède une PK `(tenant_id,id)`, y compris fichiers, prix, devis, lignes, sites et messages. Les enfants portent le tenant dans leurs FK. Index/recherche/cache/objets utilisent aussi ce scope ; aucune recherche vectorielle globale sur les documents privés. La base commune de règles est distincte et contient des sources autorisées, sans devis ni tarifs privés.

API utilise un rôle DB non propriétaire, sans BYPASSRLS ; `ENABLE` et `FORCE ROW LEVEL SECURITY` sur les tables privées. Le contexte vérifié est défini par `SET LOCAL` dans chaque transaction, jamais par un tenant de payload ; ne pas laisser de contexte sur une connexion de pool. La RLS de tenant complète les FK composites et les contrôles d'objet. **Elle ne suffit pas pour le portail** : un rôle SQL séparé n'a pas les droits de lecture générale et passe par des requêtes/DTO dédiés vérifiant `site_access`. Les accès globaux d'authentification sont encapsulés et audités.

La documentation PostgreSQL précise que les vérifications référentielles contournent la RLS ; cette conception conserve donc des clés composites et masque les erreurs d'intégrité susceptibles de révéler l'existence d'un objet. Source : https://www.postgresql.org/docs/current/ddl-rowsecurity.html (consultée le 01/10/2026).

Authentification proposée : jeton de session opaque aléatoire, seule empreinte stockée dans `sessions`, cookie Secure/HttpOnly/SameSite et protection CSRF des commandes ; hash de mot de passe robuste, limitation des tentatives et réinitialisation par jeton temporaire à usage unique. Durées de session et méthode de récupération restent configurables à valider avant T03. Chaque requête vérifie session, epoch du compte et appartenance courante ; révoquer une entreprise ne bloque pas les autres appartenances. L'authentification accède à comptes/sessions via un service restreint, sans ouvrir les tables globales au portail. Aucun stockage du secret de session dans localStorage.

## Envoi et décision
Validation fige la version et programme le PDF depuis ce snapshot. Le PDF stocke version_id, hash de contenu et hash du fichier ; un PDF d'une autre version ne peut être joint. Téléchargement brouillon marqué BROUILLON, sans effet sur l'état. Envoi crée outbox + delivery dans une transaction ; le worker ne remplace jamais le contenu de l'offre.

Un verrou sur le devis et un jeton d'offre empêchent deux offres actives. Pendant envoi, l'API bloque une acceptation concurrente jusqu'au règlement de la commande : le worker effectue contrôle, marque une intention durable, puis appelle le prestataire ; finalise ou signale une issue incertaine. En cas de crash après acceptation par le prestataire avant mise à jour DB, rapprocher par clé fournisseur/statut ; pas d'envoi aveugle. Sans API idempotente ni rapprochement, état `INCERTAIN` et résolution humaine avant reprise. Une preuve qu'une offre a été envoyée après l'acceptation concurrente doit déclencher une alerte, pas remplacer le contrat accepté.

Les emails peuvent être délivrés deux fois selon les garanties du prestataire. Le système garantit une décision commerciale et une outbox idempotentes, pas exactement une livraison. Notifications internes dédupliquées par event_id/destinataire/canal.

Implémentation du verrou logique d'offre : toutes les commandes d'envoi/décision verrouillent la ligne `quotes`, puis inspectent les livraisons rattachées à ses versions. Une livraison EN_COURS ou INCERTAIN bloque la décision concurrente et tout remplacement jusqu'à résolution ; le worker ne maintient pas de transaction ouverte pendant l'appel email. Les commandes suivent le même ordre de verrouillage et l'intention durable tient lieu de verrou entre transactions. Une confirmation active la nouvelle offre et remplace l'ancienne atomiquement ; un échec certain libère l'intention sans activer la nouvelle offre. Ne pas résoudre une issue ambiguë par une simple expiration de lease.

## Limites du schéma de référence
`schema/schema-reference.sql` matérialise les structures et FK proposées ; ce n'est pas une migration de production. Les règles qui couvrent plusieurs lignes (prix actifs, statuts, immutabilité, budgets, baseline) exigent commandes transactionnelles, contraintes supplémentaires et tests avant déploiement. Le calendrier privé global, les accès portail et les rôles SQL ne sont pas exposés à l'API générale. Les données JSON sont validées par schémas versionnés ; elles ne remplacent pas les colonnes/relations essentielles.
