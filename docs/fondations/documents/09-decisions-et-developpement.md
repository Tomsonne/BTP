# Décisions ouvertes et ordre de développement

## Priorités à valider
| Priorité | Question / décision | Hypothèse de travail | Moment bloquant |
|---|---|---|---|
| 1 | Quel métier et quels pilotes ? | Peinture intérieure, 3 à 5 entreprises pilotes | Avant recettes et promesse commerciale. |
| 1 | Qui valide rendements, omissions et moyens nécessaires ? | Un professionnel partenaire, recettes relues | Avant devis envoyé sur chantier réel. |
| 1 | Quel contenu minimum du catalogue ? | Référence, nom, unité, prix HT EUR ; compléter MO/équipements/ouvrages hors Excel initial | Avant import final et calcul. |
| 1 | Majoration ou marge, frais et TVA ? | Une politique par entreprise, figée par version | Avant moteur accepté et lancement. |
| 1 | Qui valide/envoie et quelle preuve client ? | AE ; délégation explicite ; preuve saisie au MVP | Avant envoi réel. |
| 1 | Hébergement et fournisseur IA/email ? | Services privés, contrats/usage/rétention vérifiés | Avant traitement de dossiers réels. |
| 2 | Budget IA tenant et plafond opération ? | Budget réservé par tentative, limite configurable | Avant pilote payant. |
| 2 | Durées et suppression/export ? | Valeurs opérationnelles du document 08, contrat à préciser | Avant collecte de données réelles. |
| 2 | Contrôle à quatre yeux ? | Facultatif pour artisan, activable | Avant délégation fine. |
| 2 | Ordre chantier vs avenant vs portail ? | E1 minimal, avenant manuel assisté | Après stabilité du devis. |
| 3 | Horaires/congés et personnes multi-entreprises ? | Calendrier privé global, pas de paie | Avant E2. |
| 3 | Quel partage collectif des corrections ? | Aucun par défaut | Avant E3. |
| 3 | Prix des autres métiers et mesure sur plans ? | Extensions, pas de promesse de couverture automatique | Avant extension commerciale. |

Aucune de ces décisions n'empêche d'écrire les fondations techniques proposées. Les paramètres fiscaux, le fournisseur pour données réelles et la validation professionnelle empêchent en revanche un lancement réel s'ils restent ouverts.

## Développement par dépendances
| Tâche | Livrable concret | Dépend de | Critère de sortie |
|---|---|---|---|
| T01 | Valider cadrage pilote, glossaire et règles de prix | — | Décisions priorité 1 attribuées, hypothèses approuvées ou corrigées. |
| T02 | Monorepo, CI, env fictifs et migrations initiales | T01 | Build/review ; aucun secret ; tests DB disponibles. |
| T03 | Comptes, entreprises, appartenance, invitations, autorisation | T02 | AC01–04 ; tests négatifs tenant et compte multi. |
| T04 | Moteur décimal, unités, recettes et fixtures métier | T01, T02 | AC16–19 ; exemple 40 m² exact ; postes indispensables relus. |
| T05 | Fichiers privés, quarantaine, limites et audit | T03 | AC39 ; accès aux objets contrôlé. |
| T06 | Catalogue et Excel preview/mapping/diff/publication | T04, T05 | AC05–07 et conservation historique des prix. |
| T07 | Clients, besoin/révisions, devis manuel et versions | T03–T06 | AC20–24 ; parcours utilisable sans IA. |
| T08 | Jobs durables, leases, budgets et adaptateur IA simulé | T03, T07 | AC11–15 avec panne/lease périmée. |
| T09 | Extraction/propositions/questions et contrôles métier | T04, T06–T08 | AC08–10, AC12–13 ; jeu de référence relu. |
| T10 | Revue/validation/PDF et envoi explicite outbox | T07, T08 | AC21–28, AC40 ; timeout email testé. |
| T11 | Supervision, export/purge et restore préprod | T05–T10 | AC38 ; RPO/RTO mesurés, données/export cohérents. |
| T12 | Pilote restreint et correction des recettes | T09–T11 | Aucun P0 ouvert ; coûts et corrections suivis. |
| T13 | E1 chantier, publications client et portail | T12 | AC29–30 ; accès portail testés. |
| T14 | E1 changements et avenants avec baseline | T10, T13 | AC31–33 ; aucune double augmentation. |
| T15 | E2 planning, congés et horaires selon politique | T13 | AC34–35 ; conflit inter-entreprises masqué. |
| T16 | E3 amélioration commune et nouveaux métiers | T12, décision droits | AC36–37 ; provenance/approbation et rollback. |

Les premières tâches exécutables sont T01–T03 et la création des cas de chiffrage T04. Développer d'abord le devis manuel donne une référence vérifiable à l'IA. Aucune estimation de durée n'est annoncée sans effectif, disponibilité, barèmes et niveau de maturité du pilote.
