# Permissions et portée

**AP** administrateur plateforme ; **AE** administrateur entreprise ; **DV** chargé de devis ; **CH** chef de chantier ; **EM** employé ; **CL** client portail. ✓ = autorisé ; P = sous permission additionnelle ; S = objets affectés/propres et champs autorisés ; — = interdit. Les droits sont configurés côté serveur, aucune confiance dans les boutons du navigateur.

| Action | AP | AE | DV | CH | EM | CL |
|---|---:|---:|---:|---:|---:|---:|
| Activer/suspendre tenant, suivre quotas techniques | ✓ | — | — | — | — | — |
| Lire contenu privé entreprise | — | ✓ | S | S | S | S |
| Inviter / révoquer employés / déléguer permissions | — | ✓ | — | — | — | — |
| Gérer contacts clients | — | ✓ | ✓ | S | — | S lecture |
| Importer catalogue / modifier prix et recettes | — | ✓ | P | — | — | — |
| Créer besoin / générer / corriger devis | — | ✓ | ✓ | P | — | — |
| Demander revue | — | ✓ | ✓ | P | — | — |
| Valider devis / avenant | — | ✓ | P | P | — | — |
| Exporter PDF brouillon marqué | — | ✓ | ✓ | P | — | — |
| Envoyer offre validée | — | ✓ | P | P | — | — |
| Enregistrer décision client (MVP) | — | ✓ | P | — | — | — |
| Accepter/refuser via portail (E1) | — | — | — | — | — | S |
| Voir coûts, marges et prix d'achat | — | ✓ | ✓ | P | — | — |
| Créer chantier depuis devis accepté | — | ✓ | P | ✓ | — | — |
| Gérer étapes / affectations / avancement | — | ✓ | — | S | S saisie | S lecture publiée |
| Déposer photos / messages | — | ✓ | S | S | S | S |
| Publier contenu au client | — | ✓ | — | S | — | — |
| Déclarer changement / proposer avenant | — | ✓ | P | S | S déclaration | S demande |
| Saisir temps / demander congé | — | ✓ | S | S | S | — |
| Approuver congé / résoudre conflit | — | ✓ | — | P | — | — |
| Lire audit d'entreprise / exporter données | — | ✓ | — | — | — | S données propres |
| Autoriser un retour pour amélioration collective | — | ✓ | — | — | — | — |
| Approuver publication de règles communes | ✓ | — | — | — | — | — |

AP gère l'exploitation sans accès automatique aux dossiers métier. Un accès de support exceptionnel exige une autorisation d'entreprise, un motif, une portée et une durée, avec audit ; il n'est pas développé dans le MVP. AE peut cumuler DV et CH. MVP : AP, AE, DV ; validation/envoi par AE, éventuellement délégués à DV. Un contrôle à quatre yeux est une option configurable, non un invariant imposé au petit artisan.

Les rôles sont attachés à une **appartenance**, pas au compte global. Les droits d'une entreprise A ne s'appliquent jamais à B. Un compte client peut avoir des `site_access` dans plusieurs entreprises ; la sélection d'espace est explicite. Le portail reçoit des DTO dédiés : lignes de vente autorisées, photos publiées, avancement, décisions ; aucune requête tenant générale et aucun champ de coût interne.

Le départ d'un employé désactive son appartenance, les affectations futures et ses invitations ; conserve l'attribution historique des actions. Les autorisations sont vérifiées à chaque requête et avant chaque effet de job. Un changement de rôles révoque les sessions tenant concernées (`auth_epoch`). Les URL de fichiers sont courtes ; révocation immédiate stricte exige un proxy de téléchargement qui revérifie l'accès à chaque lecture.
