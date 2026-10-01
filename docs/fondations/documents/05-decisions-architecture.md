# Décisions d’architecture proposées (ADR)

Toutes sont **PROPOSEES**, révisables et non présentées comme des choix déjà actés.

| ADR | Choix | Justification | Conséquence / limite |
|---|---|---|---|
| ADR01 | Monolithe modulaire, API et worker séparés en processus | Petite équipe, transactions métier locales, exploitation simple | Contrats de modules ; découpage en services seulement après mesure. |
| ADR02 | PostgreSQL, clés composites tenant, RLS en défense complémentaire | Cohérence des versions et refus des références croisées | Discipline de rôles DB, migrations, tests négatifs ; RLS ne remplace pas les droits d'objet. |
| ADR03 | Jobs et outbox dans PostgreSQL au MVP | Évite Redis et réduit les fenêtres de perte entre état et file | Leases, fencing et nettoyage ; mesurer contention avant changement de file. |
| ADR04 | Compte global, rôles par appartenance | Plusieurs entreprises pour une personne | Sélection tenant explicite ; révocation par espace ; calendrier privé global E2. |
| ADR05 | Calcul décimal déterministe séparé du LLM | Reproductibilité, audit et prix explicables | Test de formules et snapshots ; dépendance à une bibliothèque décimale maintenue à valider. |
| ADR06 | Ouvrages composés versionnés et coûts analytiques non facturables | Rendements, pertes et moyens nécessaires sans double comptage | Pilotage métier pour écrire les recettes ; recettes à un niveau au MVP. |
| ADR07 | Pas d'entraînement maison initial ; contexte et règles versionnés | Données pilotes limitées, coût et vitesse d'itération | Un fournisseur interchangeable via adaptateur ; évaluer avant tout fine-tuning. |
| ADR08 | Versions commerciales figées dès validation | PDF, décision et catalogue ne doivent pas diverger | Nouvelle version pour correction ; l'historique coûte du stockage. |
| ADR09 | Stockage objet privé + fichiers contrôlés | Gros fichiers hors DB, révocation et analyse | Proxy ou URL très courte selon besoin ; objets et DB sauvegardés de façon cohérente. |
| ADR10 | Budget réservé et usage par tentative | Évite qu'une panne consomme le budget par reprises sans limite | Timeouts facturés possibles ; rapprochement et provisions nécessaires. |
| ADR11 | Décision client saisie avec preuve dans MVP | Lance le pilote sans complexifier signature et portail | Ne promet pas signature probante ; analyse juridique avant portail/engagement automatisé. |
| ADR12 | Catalogue Excel importé via staging et diff | Erreurs, doublons et mises à jour contrôlés | Aucune publication partielle silencieuse ; rapport et exclusions explicites. |
| ADR13 | Aucun partage collectif implicite des corrections | Confidentialité, provenance et risques de réidentification | Autorisation et comité de revue ; règles privées restent immédiatement utilisables dans le tenant. |
| ADR14 | Planning avec réserve globale privée par compte | Évite doubles réservations inter-entreprises | Service restreint, vue « indisponible » sans détail ; volume et réservations externes à préciser. |

Pour ADR14, une contrainte d'exclusion d'intervalles peut empêcher les chevauchements au niveau base. Les types range et contraintes d'exclusion sont documentés officiellement : https://www.postgresql.org/docs/current/rangetypes.html (consulté le 01/10/2026). Le schéma fournit le type d'intervalle ; la contrainte nécessite `btree_gist` et une migration validée. Les tests métier restent nécessaires pour l'approbation de congés, les disponibilités et la confidentialité.
