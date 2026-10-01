# Cadrage — version 1.0, 1 octobre 2026

## Périmètre reformulé
Le produit transforme un cahier des charges en une **proposition de devis explicable et modifiable**, à partir des prix et paramètres propres à l'entreprise. Il aide à détecter les omissions et demande les données manquantes. Un professionnel contrôle le résultat ; le logiciel calcule les montants et n'envoie rien sans action explicite. La vision inclut chantiers, portail client, ressources et avenants.

## État des connaissances
| Nature | Éléments |
|---|---|
| Besoins confirmés | Cahier → devis ; Excel privé ; questions ; calcul exact ; correction ; versions ; validation ; PDF ; envoi explicite ; décision client ; extensions chantier/avenant/planning ; journal et coûts IA. |
| Hypothèses révisables | France, EUR, langue française ; pilote peinture intérieure ; documents PDF texte, TXT et DOCX ; un fournisseur IA ; client identifié avant validation ; décisions saisies par l'entreprise dans le MVP. |
| Recommandations | Monolithe modulaire TypeScript, React, PostgreSQL, worker ; stockage objet privé ; règles métier versionnées ; aucune formation automatique du modèle. |
| Décisions ouvertes | Métier pilote, validation des barèmes par un professionnel, TVA applicable, valeur juridique de la décision client, hébergement/fournisseur, conservation et budget. |

## Sources inspectées
- Texte fourni : `Texte collé.txt`, lu intégralement ; il constitue l'expression de besoin.
- Dépôt annoncé : https://github.com/Tomsonne/BTP ; lecture de l'API Contents le 01/10/2026 : réponse « This repository is empty ». Aucun fichier ni architecture existante n'a été supposé.
- Ce dossier propose des fondations ; il ne décrit pas une application déjà implémentée et n'est pas publié sur GitHub.

## MVP et étapes suivantes
| Lot | Inclus | Limites |
|---|---|---|
| MVP | Entreprises, comptes multi-entreprises, droits ; clients ; Excel matériaux/prix ; saisie unités et ressources complémentaires ; bibliothèque d'ouvrages peinture validés ; import du besoin ; génération asynchrone ; questions ; contrôles ; devis manuel ; versions ; validation interne ; PDF ; envoi email explicite ; saisie de la décision avec preuve ; audit, quotas et sauvegardes. | Pas de mesure automatique sur plans ; pas de reconnaissance fiable de scans ; pas de signature électronique intégrée ; pas de paie, facture ou comptabilité. |
| E1 | Chantier depuis version acceptée ; tâches/étapes, photos modérées, avancement, portail client, messages ; avenant manuel assisté et décision client. | Portail accessible uniquement aux contacts autorisés ; les suggestions ne valent pas engagement. |
| E2 | Affectations, indisponibilités, prévention des conflits, horaires et congés selon politique validée ; suivi budgétaire chantier ; davantage de métiers. | Pas de calcul réglementaire automatique des heures supplémentaires ni de paie. |
| E3 | OCR assisté, comparaison de documents, détection de changements, amélioration contrôlée des règles, éventuel ajustement de modèle après preuve de besoin. | Réutilisation collective soumise à autorisation et évaluation distinctes. |
| Extensions hors périmètre | Facturation, paiements, comptabilité, paie, achats et stocks réels. | Une décision produit et un dossier spécifique sont nécessaires. |

La bibliothèque commune peut traiter plusieurs métiers dès le modèle, mais seuls les ouvrages du pilote sont commercialement testés. Un métier inconnu déclenche une alerte et une saisie professionnelle, pas une garantie de couverture.

## Glossaire commun
| Terme | Sens |
|---|---|
| Entreprise / tenant | Espace de données isolé d'un client SaaS. |
| Appartenance | Relation entre un compte et une entreprise, avec rôles et état ; un compte peut en avoir plusieurs. |
| Client | Personne ou organisation bénéficiaire ; ses contacts et futurs comptes portail sont séparés des employés. |
| Cahier des charges | Besoin source ; chaque modification crée une révision de besoin. |
| Snapshot d'entrée | Copie cohérente du besoin, catalogue, règles et paramètres utilisée par une génération. |
| Matériau | Ressource consommable, prix d'achat et unité explicites. |
| Ressource | Matériau, main-d'œuvre, équipement ou frais ; les frais forfaitaires sont traçables. |
| Ouvrage | Recette de ressources pour une unité de travail ; rendements et pertes explicites. |
| Ligne de devis | Poste vendu ; il peut être lié à un ouvrage, mais garde ses propres valeurs figées. |
| Version de devis | Ensemble des lignes, hypothèses, totaux, sources et conditions à un instant donné. |
| Révision d'édition | Compteur technique d'un brouillon ; ne remplace pas le numéro de version commerciale. |
| Proposition IA | Résultat candidat, questions et alertes ; jamais un devis accepté. |
| Blocage | Manque ou erreur qui interdit la validation, même si une génération technique a réussi. |
| Devis de référence | Version acceptée ; base immuable du chantier. |
| Changement de périmètre | Écart documenté au périmètre contractuel courant. |
| Avenant | Document versionné qui chiffre un changement et ne produit d'effet qu'après acceptation. |
| Outbox | Événement enregistré dans la même transaction que la décision à transmettre. |
| Idempotence | Plusieurs appels avec la même clé et le même contenu produisent le même effet métier. |

## Expérience d'utilisation
Navigation courte : Projets, Devis, Catalogue, Paramètres ; extensions ajoutées après activation. Écran devis : besoin → questions → lignes → validation. Prix et quantités inconnus sont affichés « À renseigner », jamais zéro par défaut. Les valeurs estimées portent source, hypothèse et confirmation. Les totaux se recalculent ; le résumé indique précisément les blocages. Un brouillon peut être enregistré même incomplet. Responsive, clavier, contrastes et états de chargement/erreur font partie de l'acceptation.
