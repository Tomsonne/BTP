# Registre des risques

P0 = empêche le lancement pilote ; P1 = requis pour un pilote exploitable ; P2 = avant l'extension concernée. Priorité qualitative, sans fréquence inventée.

| ID | Scénario | Conséquence | Prévention / détection | Priorité | Responsable proposé |
|---|---|---|---|---|---|
| R01 | Un identifiant B injecté dans une requête A | Fuite de dossier/prix | FK composites, requêtes scopées, RLS, tests API/jobs/export/cache | P0 | Backend |
| R02 | Un client reçoit un DTO salarié | Fuite de marge ou message interne | DTO portail dédiés, site_access, champs en liste blanche | P0 E1 | Backend |
| R03 | Quantité ou prix inventé | Devis erroné et perte financière | Source/hypothèse, blocage, questions et confirmation professionnelle | P0 | Métier + IA |
| R04 | Rendement ou unité incohérente | Sous-chiffrage | Dimensions, recettes validées, cas de référence | P0 | Métier |
| R05 | Ouvrage et composants vendus ensemble | Surfacturation | Mode exclusif et composant analytique non facturable | P0 | Chiffrage |
| R06 | Catalogue modifie un devis accepté | Contrat/PDF incohérents | Prix historisés, snapshots et hash PDF | P0 | Backend |
| R07 | Double clic génération/envoi | Coûts et emails doublés | Clé idempotente, empreinte, outbox unique ; rapprochement email | P0 | Backend |
| R08 | Deux utilisateurs éditent simultanément | Perte d'une correction | ETag/edit_revision, 409 et comparaison | P0 | Backend + Front |
| R09 | Besoin modifié pendant génération | Résultat appliqué au mauvais périmètre | Snapshot, contrôles à publication ET application | P0 | IA |
| R10 | Worker redémarre après appel IA | Appel facturé plusieurs fois | Leases, fencing, limite tentatives, usage incertain | P1 | Exploitation |
| R11 | Crash après envoi externe | Email perdu ou doublé | Idempotence prestataire, état INCERTAIN, rapprochement | P1 | Exploitation |
| R12 | Texte contient une injection de prompt | Action ou référence indue | Sources non fiables, aucune capacité d'action LLM, références autorisées | P0 | Sécurité + IA |
| R13 | XLSX zip bomb / macro / formule externe | Exécution, blocage ou exfiltration | Refus macros, décompression limitée, sandbox, limites CPU | P0 | Sécurité |
| R14 | Fournisseur indisponible ou cher | Arrêt du parcours ou dépassement | Devis manuel disponible, quotas, timeout, budget par tentative | P1 | Exploitation |
| R15 | Réutilisation de retour « anonymisé » | Réidentification, secret commercial | Autorisation, minimisation, revue humaine ; rejeter si risque résiduel | P0 E3 | Produit + Juridique |
| R16 | Départ employé sans révocation | Accès durable aux chantiers | Appartenance désactivée, sessions invalidées, jobs recontrôlés | P0 | Backend |
| R17 | Sauvegarde inutilisable / fichiers manquants | Perte du service/historique | Restore isolé périodique avec hashes, références et tests tenant | P1 | Exploitation |
| R18 | Deux avenants pour le même +40 m² | Double augmentation du contrat | Changement unique, baseline + verrou site | P0 E1 | Backend |
| R19 | Affectations/congés concurrents | Équipe indisponible | Réserve globale privée, exclusion d'intervalles, 409 | P0 E2 | Planning |
| R20 | Photo publiée par erreur | Vie privée ou secret client exposé | Privé par défaut, contrôle publication, révocation | P0 E1 | Front + Backend |
| R21 | Migration casse snapshots anciens | Devis ancien illisible | Schémas JSON versionnés, migration additive, lecteurs compatibles | P1 | Backend |
| R22 | TVA/mentions/acceptation inadaptées | Litige commercial | Paramètres validés, vérification juridique spécifique au pilote | P0 | Produit + Juridique |
| R23 | Hypothèse de sécurité erronée en hauteur | Moyen d'accès inapproprié | Question hauteur/environnement, validation professionnelle, aucune prescription automatique | P0 | Métier |
| R24 | Acceptation concurrente avec remplacement | Deux contrats prétendument actifs | Verrou devis, intention d'envoi durable, offre active unique, résolution d'issue incertaine | P0 | Backend |

Les cas R22 et R23 ne sont pas résolus par un modèle plus puissant. Il faut définir ce que le professionnel confirme, les limites du service et les justificatifs conservés.
