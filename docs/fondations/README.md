# Fondations du SaaS BTP — dossier de conception 1.0

Le produit prépare un devis détaillé depuis un besoin client et les données de l’entreprise. L’IA propose, le moteur calcule et un professionnel valide. MVP recommandé : peinture intérieure ; chantier, portail, avenants et planning sont modélisés comme extensions.

## Lecture conseillée
1. [Cadrage, périmètre et glossaire](documents/01-cadrage.md).
2. [Règles métier et calculs](documents/02-regles-metier.md) et [permissions](documents/03-permissions.md).
3. [Architecture et contrats](documents/04-architecture.md), [ADR](documents/05-decisions-architecture.md).
4. [Diagrammes commentés](documents/12-diagrammes-commentes.md) : 39 sources, couvrant A à Q et les ERD séparés.
5. [Dictionnaire](documents/10-dictionnaire-donnees.md) : 50 tables, et [schéma SQL de référence](schema/schema-reference.sql).
6. [Risques](documents/06-risques.md), [critères d’acceptation](documents/07-acceptation.md), [exploitation](documents/08-exploitation-et-verifications.md) et [traçabilité](documents/11-tracabilite.md).
7. [Décisions prioritaires et tâches par dépendance](documents/09-decisions-et-developpement.md).

## Organisation
- `documents/` : documents de référence en français.
- `diagrammes/` : Mermaid et PlantUML modifiables.
- `rendus/` : diagrammes SVG rendus et inspectés selon le rapport de vérification.
- `schema/` : définition JSON, DDL PostgreSQL et exclusion planning optionnelle.
- `verification/` : manifest et rapport des contrôles effectivement réalisés.

Le schéma SQL est un point de départ testé selon le rapport, pas une migration prête à déployer. Les états, permissions, règles de validation et invariants transactionnels doivent être implémentés. Aucune fonctionnalité ni conformité de l’application future n’est annoncée comme acquise.

Les diagrammes sont découpés pour une lecture verticale ; certaines entités externes sont répétées dans les ERD pour rendre chaque partie compréhensible. Les cardinalités minimales du MCD décrivent les objets métier valides ; les tables de brouillon permettent une construction progressive avant validation.

## Décisions prioritaires
Métier pilote, professionnel référent, barèmes/units/rendements, politique marge/majoration et taxes, habilitations/envoi et preuve client, fournisseurs et politique des données. Premières tâches : T01 cadrage, T02 socle/CI/migrations, T03 isolation et accès, T04 moteur de chiffrage sur fixtures.
