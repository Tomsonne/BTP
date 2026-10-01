# Règles métier et invariants

Les identifiants RM ci-dessous sont utilisés dans les diagrammes, critères et risques. **M** = MVP, **E** = extension.

| ID | Lot | Règle / invariant |
|---|---|---|
| RM01 | M | Toute entité privée porte `tenant_id`. Toute référence privée est une FK composite `(tenant_id, id)`. Le tenant actif vient d'une appartenance authentifiée, jamais d'un champ client accepté sans contrôle. |
| RM02 | M/E | Autorisation = compte actif + appartenance active + permission + portée de l'objet. Le client portail doit aussi avoir un accès explicite au chantier et à la visibilité du contenu. |
| RM03 | M | Besoin, réponses et pièces jointes constituent une révision immuable. Une modification crée une révision ; un job déjà lancé garde son snapshot. |
| RM04 | M | Aucune quantité ni prix inventé silencieusement. Chaque valeur est EXPLICITE, ESTIMEE ou MANUELLE, avec source et hypothèse. Une estimation indispensable non confirmée interdit la validation. |
| RM05 | M | Les calculs appartiennent au moteur déterministe ; le modèle propose uniquement des références, quantités candidates et explications. |
| RM06 | M | Les dimensions des unités doivent correspondre ; une conversion physique exige une règle et ses paramètres validés. m² → L nécessite rendement et nombre de couches, pas une conversion générique. |
| RM07 | M | Une ligne est facturée une fois : ouvrage agrégé OU composants facturables. Ses composants analytiques ont `facturable=false`. Les frais/équipements communs ont une clé de périmètre pour éviter leur duplication. |
| RM08 | M | Prix du catalogue historisés ; copie des prix, rendements, pertes, taxes, marges et libellés dans chaque version figée. Une mise à jour du catalogue ne modifie jamais ces snapshots. |
| RM09 | M | Une version passe EN_REVUE puis VALIDE uniquement avec tous les champs obligatoires, zéro blocage et une permission de validation. VALIDE fige le contenu ; toute correction ultérieure crée une nouvelle version. |
| RM10 | M | L'envoi exige VALIDE, PDF de cette version et destinataire vérifié. Action humaine explicite + transaction outbox ; l'IA n'a pas cette permission. |
| RM11 | M | La décision référence précisément la version envoyée et une preuve. Une seule version acceptée par devis ; acceptation possible seulement pour l'offre active, non expirée, non remplacée. |
| RM12 | M | Idempotence sur génération, confirmation d'import, création de version, envoi, décision client et création de chantier/avenant. Même clé + contenu différent → 409. |
| RM13 | M | Modification concurrente contrôlée par `edit_revision` / ETag. Un job dont la révision source n'est plus courante est OBSOLETE : visible pour comparaison, non fusionné automatiquement. |
| RM14 | M | Jobs durables, leases et token de possession ; reprise limitée ; pas de transaction DB ouverte pendant l'appel IA. Notification au moins une fois, déduplication quand le fournisseur le permet. |
| RM15 | M | Budget par tenant réservé avant appel ; coût réel ou estimé et tentatives tracés ; quota insuffisant bloque le lancement sans changer le devis. |
| RM16 | M | Fichiers non fiables : quarantaine, limites, analyse, parsing isolé, aucune exécution de macro/lien/commande. Contenu cité comme données, aucune capacité d'envoi pour le modèle. |
| RM17 | M/E | Retours privés non partagés par défaut ; publication collective uniquement après autorisation distincte, provenance, contrôle de confidentialité, évaluation et approbation. |
| RM18 | M | Invitation à usage unique, jeton haché et expiration ; révocation d'appartenance invalide immédiatement les sessions/accès de cette entreprise et les jobs non autorisés à poursuivre. |
| RM19 | M | Journal append-only des changements critiques, tenant, acteur, objet, version et corrélation ; pas de secrets, tokens ni contenu client complet dans les logs. |
| RM20 | M | Archivage distinct de suppression ; export et purge contrôlés ; exceptions de conservation motivées ; suppression des objets, index et caches ; sauvegardes expirées selon politique. |
| RM21 | E1 | Chantier créé une fois depuis la version acceptée ; référence conservée même après archivage du catalogue. |
| RM22 | E1 | Avenant lie chantier, devis de référence, changement et version de baseline. Seuls les avenants acceptés impactent le budget contractuel. |
| RM23 | E1 | Deux avenants ne couvrent pas deux fois le même changement ; acceptation atomique sur la baseline encore courante. Un conflit oblige à rebaser une nouvelle version et à la faire revalider. |
| RM24 | E1 | Photos/messages privés par défaut ; publication client explicite ; suppression/revocation retire leur accès futur. Avancement calculé par poids, jamais présenté comme mesure physique automatique. |
| RM25 | E2 | Intervalles planning demi-ouverts `[début, fin)` ; absence et affectation bloquante partagent un calendrier global par compte pour détecter les conflits entre ses entreprises sans divulguer leurs détails. |
| RM26 | M | Paramètres/règles/prompts/sources/modèle utilisés sont versionnés et conservés avec le job. Une règle commune ne contient aucun prix privé d'une entreprise. |

## Cycle commercial et versions
Les états commerciaux appartiennent à `quote_versions` (diagramme H). `quotes` conserve les pointeurs `draft_version_id`, `active_offer_version_id`, `accepted_version_id` ; son état affiché est dérivé. Le statut technique IA appartient à `generation_jobs`, sans transition commerciale implicite.

BROUILLON peut être incomplet et modifiable. EN_REVUE verrouille l'édition ; un réviseur peut renvoyer en BROUILLON avec motif. VALIDE fige le contenu. ENVOYE signifie envoi confirmé par le prestataire, pas livraison prouvée. Un outbox en attente n'avance pas cet état. ACCEPTE, REFUSE, EXPIRE et REMPLACE sont immuables comme contenus et tracés comme événements. ABANDONNE clôt un brouillon ou une revue. L'archivage est un attribut et ne réécrit pas l'état commercial.

Une correction d'une offre VALIDE ou ENVOYE crée une nouvelle version BROUILLON. L'ancienne offre envoyée reste active jusqu'à l'envoi effectif de la nouvelle ; remplacement et activation sont transactionnels. Si l'ancienne est acceptée entre-temps, l'envoi de la nouvelle est interdit : passage par avenant. Une nouvelle version validée peut remplacer une ancienne version VALIDE non envoyée. Après acceptation, le devis ne peut plus recevoir d'offre concurrente.

Décisions MVP : l'admin entreprise enregistre la décision du client et joint email/document/motif après vérification de la version. Ce n'est pas une signature électronique certifiée. E1 ajoute une décision depuis le portail avec challenge et preuve adaptés à la décision juridique retenue.

## Données requises avant validation
Identité de l'entreprise et du client, lieu/contexte utile, devise unique EUR, validité de l'offre, description claire, quantité strictement positive des postes ordinaires, unité, prix de vente ≥ 0, taux de taxe validé, sources/coûts selon politique, hypothèses critiques confirmées, moyens d'accès décidés si nécessaires. Une ligne gratuite nécessite un motif et reste visible. Un poste indispensable non chiffré bloque ; une exclusion de périmètre doit être explicite et ne peut masquer un moyen nécessaire pour exécuter un poste inclus.

## Chiffrage exact — convention proposée à valider
Types : `numeric(18,6)` pour quantités/coûts/prix unitaires, `numeric(9,6)` pour taux fractionnaires, `numeric(18,2)` pour montants EUR. Calcul intermédiaire décimal de précision au moins 28, jamais `Number` flottant pour le domaine argent. Arrondi HALF_UP, 2 décimales au montant de ligne ; total HT = somme des lignes arrondies. TVA = arrondi par groupe de taux du total HT du groupe × taux ; TTC = HT + TVA. Pas de remise globale dans le MVP (extension à définir avant ajout).

- **Achat** : montant versé au fournisseur, hors taxe dans la convention retenue.
- **Coût direct** : matériaux + temps × coût horaire + équipements + frais directs.
- **Coût de revient** : coût direct + frais indirects explicitement alloués.
- **Majoration** `u` : vente HT = revient × (1 + u).
- **Marge sur vente** `m` : vente HT = revient / (1 − m), avec 0 ≤ m < 1.
- **Marge en EUR** : vente − revient. La politique utilise soit `MAJORATION`, soit `MARGE_SUR_VENTE`, jamais les deux en cascade.

Exemple fictif : revient 100 €, majoration 25 % → vente 125 €, marge sur vente 20 %. Une marge sur vente de 25 % donne 133,333333 € de prix unitaire, soit 133,33 € pour une unité. Ces taux ne constituent pas des tarifs recommandés.

Ouvrage peinture fictif de 40 m², 2 couches, rendement 10 m²/L/couche, perte 10 % : besoin 8,8 L. Si seuls des pots de 5 L à 30 € sont achetables, coût matériaux = ceil(8,8 / 5) × 30 = 60 €. Le poste couvre ici cet achat complet ; aucune facturation à 8,8 L en parallèle. Si rendement de travail = 8 m²/h **pour l'ensemble des 2 couches**, durée = 5 h ; ne pas multiplier de nouveau par 2. Avec 28 €/h et frais directs 20 € : direct 220 €, frais indirects alloués 10 % = 22 €, revient 242 €, majoration 25 % = 302,50 €, TVA fictive 20 % = 60,50 €, TTC 363 €. TVA réelle et règles d'allocation à valider pour chaque cas.

Pertes appliquées aux consommables, pas automatiquement à la main-d'œuvre. Arrondir les emballages au périmètre décidé (ligne ou chantier), puis répartir le coût sans le dupliquer. Rendement, unité de rendement et portée des couches sont indispensables. Conversions m↔cm possibles si même dimension ; kg↔L seulement avec densité validée. Les recettes d'ouvrages sont sans cycle ; un ouvrage enfant est développé une seule fois avec provenance. MVP : recettes à un niveau pour limiter les ambiguïtés.

Coefficient de difficulté proposé : temps prévu = quantité / rendement × coefficient, avec coefficient strictement positif, valeur par défaut 1 et justification professionnelle pour toute autre valeur. La politique précise les postes concernés ; ne pas multiplier tous les matériaux et toutes les marges. Rendement, coefficient et justification sont copiés dans `pricing_snapshot`/`provenance`. Un coefficient proposé par l'IA demeure une estimation à confirmer. Avancement chantier : moyenne pondérée des tâches à l'intérieur de chaque étape, puis des étapes ; tâches sans poids ou étape sans tâches → avancement non calculable, pas un pourcentage inventé.

## Changement de périmètre
Le +40 m² de peinture n'est pas déduit d'un message et facturé automatiquement. Il produit un `scope_change` candidat ; le chef précise ouvrage, quantité et unité, compare aux travaux déjà inclus, choisit si le tarif contractuel est applicable, puis crée un avenant. Les frais déjà couverts (installation, accès encore utilisable) ne sont pas ajoutés une deuxième fois. Des lignes négatives sont possibles uniquement en avenant, avec motif de suppression ; le total contractuel restant doit rester cohérent.
