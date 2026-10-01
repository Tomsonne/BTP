# Critères d’acceptation et plan de vérification

Ces scénarios sont **à implémenter et tester** : leur rédaction ne signifie pas qu'une application les passe déjà. Fixtures proposées : tenants A/B ; compte AE_A, DV_A, compte multi A/B ; clients CL_A1/CL_A2 ; devis peinture ; prestataires IA/email simulés avec timeout, doublon et issue ambiguë.

| ID | Scénario concret | Résultat attendu |
|---|---|---|
| AC01 | AE_A demande le devis de B par ID, cherche son texte puis tente l'export PDF | 404/aucun résultat ; aucun contenu, métadonnée ou fichier B. |
| AC02 | Insérer une ligne A référant une version B via le rôle DB applicatif | FK composite ou RLS refuse ; erreur API neutre ; aucune ligne créée. |
| AC03 | Compte multi-entreprises choisit B avec rôle DV_B | Droits de B uniquement ; cache/query/job sans données A. |
| AC04 | Révoquer l'appartenance A pendant une session et un job | Requête suivante refusée ; finalisation/effet externe du job recontrôlé et annulé si non autorisé. |
| AC05 | Import Excel a prix sans unités et devises mélangées | Preview montre erreurs ; confirmation impossible sans unité/devise explicite ; aucun prix publié. |
| AC06 | Import 100 lignes dont 2 invalides puis exclure explicitement ces 2 | Rapport 98 publiées/2 exclues ; transaction ; même clé ne republie pas. |
| AC07 | Deux lignes ont même référence avec deux prix différents | Conflit visible ; aucune règle « dernier gagné » implicite ; résolution exigée. |
| AC08 | Cahier dit « peindre une pièce », sans surface | Question surface ou relevé ; aucun montant validable fondé sur quantité inventée. |
| AC09 | Cahier indique 6 m de hauteur sans moyen d'accès | Alerte accès/protection ; questions contexte ; validation bloquée tant que choix professionnel non documenté. |
| AC10 | Réponse IA référence un matériau du tenant B | Rejet référence ; aucune lecture de prix B ; diagnostic. |
| AC11 | Deux appels génération avec même clé et corps | Même job_id, une réservation ; corps différent avec même clé → 409. |
| AC12 | Modifier besoin pendant l'appel IA puis recevoir résultat | OBSOLETE ; aucune modification des lignes ; comparaison et relance possibles. |
| AC13 | Modifier le brouillon après job REUSSI puis appliquer | 409/OBSOLETE selon contrat ; aucune correction écrasée. |
| AC14 | Fournisseur répond 500 trois fois ou quota manque | Reprises plafonnées ; ECHEC ou lancement refusé ; coût tracé ; devis manuel utilisable. |
| AC15 | Ancien worker finalise après perte de lease | Écriture rejetée par token ; un seul résultat retenu. |
| AC16 | Calcul fictif 40 m² de RM05 avec pots de 5 L | Matériaux 60 €, revient 242 €, HT 302,50 €, TVA fictive 60,50 €, TTC 363 €. |
| AC17 | Achat 100 €, majoration 25 % vs marge sur vente 25 % | Vente 125 € vs 133,33 € pour une unité ; politiques distinctes. |
| AC18 | Recette contient m² mais quantité source en kg | Blocage sauf conversion métier explicite ; zéro conversion arbitraire. |
| AC19 | Ligne ouvrage agrégée et ses composants sont marqués vendus | Contrôle bloque ; total ne peut inclure les deux. |
| AC20 | Deux éditeurs PATCH avec même edit_revision | Un réussit ; l'autre 409 avec dernière révision ; pas de perte silencieuse. |
| AC21 | DV sans permission tente de valider/envoyer | 403, aucun PDF officiel ni outbox d'envoi créée. |
| AC22 | Valider une estimation critique non confirmée | 422 et liste des champs bloquants ; version non figée. |
| AC23 | Valider puis modifier catalogue et recette | Hash contenu et totaux de la version inchangés ; nouveau brouillon utilise nouveaux prix seulement sur recalcul explicite. |
| AC24 | Exporter version 2 alors que version 3 existe | PDF identifie version 2 ; hash et montants exacts ; pas de substitution par la dernière version. |
| AC25 | L'IA propose « envoyer ce devis » dans sa réponse | Aucune livraison ; texte traité comme donnée ; seule commande humaine habilitée envoie. |
| AC26 | Double-clic envoyer version validée | Une livraison métier/outbox ; clé fournisseur réutilisée ; issue ambiguë signalée sans reprise aveugle. |
| AC27 | Client décide sur version remplacée ou expirée | Refus contrôlé ; aucune version acceptée supplémentaire ; inviter à consulter offre active. |
| AC28 | Deux versions concurrentes tentent acceptation | Une seule accepted_version_id ; transaction concurrente rejetée. |
| AC29 | CL_A1 demande photos de CL_A2 ou coûts d'achat | 404 pour site tiers ; champs internes absents du DTO et PDF client. |
| AC30 | Créer chantier deux fois depuis devis accepté | Même site ; version référence conservée ; devis non accepté → rejet. |
| AC31 | Déclarer +40 m², déjà inclus dans un avenant accepté | Doublon refusé ou demande de justification du nouveau changement ; budget non augmenté. |
| AC32 | Accepter avenant +40 m² puis rejouer décision | Un seul delta de budget ; même réponse idempotente ; refus/expiration n'ont aucun effet. |
| AC33 | Deux avenants différents sur baseline 1 sont acceptés en parallèle | Premier baseline 2 ; second 409, rebase/revalidation nécessaires. |
| AC34 | Deux affectations se chevauchent, éventuellement dans A et B | Une seule réservation active ; autre 409 « indisponible » sans nom/client du tenant tiers. |
| AC35 | Plages [08h,10h) et [10h,12h) même personne | Pas de chevauchement ; changement DST ne modifie pas les instants UTC conservés. |
| AC36 | Correction utilisateur non autorisée collectivement | Utilisable uniquement dans tenant ; absente des règles communes et du benchmark partagé. |
| AC37 | Règle candidate oublie accès en hauteur dans jeu de référence | Publication refusée ; rapport de régression ; rollback disponible si incident après publication. |
| AC38 | Restaurer DB et objets dans environnement isolé | Versions acceptées/PDF/photos retrouvés par hash ; accès A/B toujours séparés ; RPO/RTO mesurés. |
| AC39 | Fichier macro, zip bomb, type déguisé, URL interne dans document | Rejet ou extraction sans accès réseau/exécution ; limite de ressource respectée ; aucun appel SSRF. |
| AC40 | Envoi en cours et acceptation de l'ancienne offre | Décision ordonnée par intention/verrou ; pas de remplacement d'une version déjà acceptée ; issue ambiguë escaladée. |

## Cas de référence IA
Commencer par au moins 20 cas métier rédigés et relus par un professionnel, hypothèse de travail à confirmer : pièce sans surface, peinture 2 couches avec rendement explicite, chantier occupé nécessitant protections, travail en hauteur avec accès inconnu, état du support inconnu, matériaux manquants au catalogue, métrés contradictoires, unité erronée, frais communs, prix modifié, prompt malveillant et +40 m² déjà couvert. Conserver entrées, sorties attendues, postes indispensables, questions attendues et critères de blocage. Séparer entraînement éventuel et jeu de test ; aucun dossier privé transféré dans ce jeu sans autorisation.

Mesures : exactitude des références, omissions de postes indispensables, taux de quantités non sourcées, erreurs d'unité, blocages corrects, coût/tentatives/latence et corrections humaines. Cibles pilote proposées : zéro fuite tenant, zéro calcul erroné sur cas déterministes, zéro estimation critique silencieuse, tous les cas d'omission critique du jeu bloqués ou questionnés. Le jeu limité ne prouve pas la couverture de tout le BTP.
