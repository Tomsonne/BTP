# Rapport de vérification — dossier de conception 1.0

## Contrôles effectivement réalisés
- 39 sources rendues : 37 Mermaid par Mermaid CLI 11.12.0 et 2 PlantUML par PlantUML 1.2025.10.
- Chaque SVG parsé en XML, sans message d'erreur de syntaxe et sans HTML `foreignObject` ; couleurs hsl normalisées en hex équivalents pour compatibilité d'export.
- Contrôle de correspondance source/manifest et empreintes SHA256 ; noms, rôles, cardinalités et transitions relus.
- Contrôle automatique des rangées pour les nœuds Mermaid munis de coordonnées : maximum 5 nœuds sur une même ordonnée. Vues UML et états examinés visuellement ; séquences ≤ 5 participants par construction.
- 50 tables et dictionnaire dérivés du même modèle JSON ; cibles FK et liens locaux vérifiés.
- SQL de référence exécuté intégralement dans PGlite 0.3.14 (PostgreSQL WebAssembly), avec extension btree_gist pour le planning.
- 17 contrôles SQL réussis, détaillés dans `sql-checks.json` : FK inter-tenant, RLS sur clients, contexte transactionnel, contraintes budget/devise/TTC, unicité des acceptations, pointeurs de version, conflit planning inter-entreprises et plages adjacentes.
- Exemple de chiffrage RM05 recalculé avec Decimal Python : HT 302,50 €, taxe fictive 60,50 €, TTC 363 €.
- Présence de RM01–RM26 et AC01–AC40 vérifiée ; dossiers et liens internes contrôlés.
- Lecture HTML vérifiée dans Chromium headless sur écran 1440×1000 et mobile 390×844 : 39 images chargées, aucun lien d'ancre cassé, aucun message d'erreur JavaScript, commande de zoom fonctionnelle, aucun débordement horizontal de page sur mobile. Captures examinées pour l'introduction et une vue ERD ; les sources des diagrammes restent disponibles pour modifications.

## Limites précises
Ces contrôles portent sur les **artefacts de conception**. L'application n'existe pas encore. Les 40 critères d'acceptation sont à développer/tester ; ils ne sont pas annoncés comme réussis. Les tests de RLS exécutés concernent des fixtures de clients et un rôle SQL non privilégié, pas tous les parcours futurs. Les tests SQL ne prouvent ni sécurité globale, ni exactitude des recettes métier, ni immutabilité applicative.

Le DDL n'implémente pas toutes les transitions métier, les guards de snapshot figé, les rôles portail, l'audit append-only, l'approbation des recettes ou les commandes transactionnelles d'envoi/avenant. Ils sont explicitement décrits pour l'implémentation. Une vraie instance PostgreSQL de l'hébergeur devra exécuter les migrations et les tests de concurrence multi-connexions. Aucune sauvegarde réelle ni restauration production n'a été testée ici.

Vérifications juridiques, fiscales et professionnelles encore ouvertes ; aucun statut de conformité acquis. Les fournisseurs, coûts réels, RPO/RTO et versions logicielles du futur produit restent à valider.
