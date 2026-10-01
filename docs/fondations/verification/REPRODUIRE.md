# Reproduire les contrôles

Les fichiers de résultat sont des preuves des contrôles effectués, pas des résultats de tests de l’application.

## SQL
Depuis `verification/`, avec Node.js compatible :
```sh
npm install --no-audit --no-fund
npm run check-schema
```
Le script exécute le schéma et l’exclusion planning dans PostgreSQL WebAssembly via PGlite. Il utilise uniquement des fixtures fictives et n’accède à aucune base externe. Les sorties sont écrites dans `sql-checks.json`.

## Diagrammes
Rendre chaque `.mmd` avec Mermaid CLI 11.12.0 et chaque `.puml` avec PlantUML 1.2025.10. Configuration Mermaid utilisée : thème neutral, htmlLabels false, direction définie dans chaque source. PlantUML utilise le moteur Smetana déclaré dans les sources. Sources et SHA256 figurent dans le manifest. Les SVG utilisent les mêmes couleurs, normalisées en hex pour compatibilité d’export.

## Avant déploiement
Exécuter les migrations sur PostgreSQL de l’hébergeur et écrire les tests AC01–AC40. Ajouter les contrôles d’immutabilité, de permission portail et les transactions métier avant d’autoriser un devis réel.
