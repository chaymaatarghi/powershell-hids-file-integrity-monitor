# HIDS PowerShell — File Integrity Monitoring & Email Alerts

## Présentation

Projet académique de **sécurité des systèmes d'exploitation** : développement en équipe d'un système de détection d'intrusion basé sur l'hôte (**HIDS**) sous Windows, à l'aide de PowerShell.

Le système surveille des fichiers sélectionnés, compare leurs empreintes **SHA-256** à un état de référence (*baseline*), journalise les changements et peut envoyer une alerte par e-mail via SMTP.

## Fonctionnalités

- Création d'une baseline SHA-256 des fichiers configurés.
- Détection des fichiers créés, modifiés et supprimés par comparaison avec la baseline.
- Surveillance périodique et journalisation des événements.
- Notification SMTP en cas de changement.
- Menu d'administration en console : consultation et modification des cibles, test d'e-mail, régénération de la baseline, lecture des logs.
- Stockage des identifiants SMTP avec `Export-Clixml` (DPAPI sous Windows) dans un fichier local non publié.

## Architecture du projet

| Fichier | Rôle |
| --- | --- |
| `GenerateBaseline.ps1` | Créer la baseline initiale |
| `DetectChanges.ps1` | Vérifier ponctuellement les changements |
| `Monitor.ps1` | Surveiller périodiquement, journaliser et alerter |
| `Admin.ps1` | Menu d'administration |
| `hids.config.example.json` | Exemple de configuration sans adresse personnelle |
| `.gitignore` | Exclure secrets, logs et fichiers générés |

## Installation et démonstration (Windows)

**Prérequis :** Windows 10/11, PowerShell 5.1 ou version compatible, droits adaptés aux fichiers surveillés.

1. Copier les scripts dans `C:\HIDS`.
2. Copier `hids.config.example.json` sous le nom `C:\HIDS\hids.config.json`.
3. Adapter `Targets`, `BaselinePath`, `LogPath` et les paramètres SMTP à votre environnement.
4. Créer le fichier de test `C:\HIDS\Test.txt`.
5. Exécuter `GenerateBaseline.ps1` pour enregistrer l'état initial.
6. Modifier le fichier de test, puis lancer `DetectChanges.ps1` pour constater une modification.
7. Pour la surveillance continue, lancer `Monitor.ps1`. L'envoi d'e-mail nécessite une configuration SMTP valide et des identifiants locaux créés avec `Get-Credential | Export-Clixml`.

**Important :** `admin@example.com` est une adresse fictive de démonstration. Les identifiants SMTP réels et le fichier `smtp.cred` ne doivent jamais être ajoutés au dépôt.

## Résultats du projet académique

Les rapports fournis documentent :
- La génération d'une baseline SHA-256.
- La détection d'une modification du fichier `C:\HIDS\Test.txt`.
- L'écriture d'événements dans un journal.
- La réception d'alertes par e-mail.
- La création d'une tâche planifiée Windows et l'utilisation du menu d'administration.

## Démonstration vidéo

[**Voir la démonstration du HIDS PowerShell (MP4, 28 secondes)**](HIDS_demo_anonymisee_discrete.mp4)

Cette vidéo est un extrait anonymisé d'une démonstration réalisée dans le cadre du projet académique. Elle montre la surveillance de fichiers et la détection de modifications dans le laboratoire Windows.

## Captures de démonstration

### Détection d'une modification

![Détection d'une modification de fichier](screenshots/d%C3%A9tection%20du%20fichie.png)

### Menu d'administration PowerShell

![Menu d'administration du HIDS](screenshots/menu%20d'administration.png)

### Journal des alertes

![Journal de surveillance et d'alertes](screenshots/journal%20hids.log%20avec%20d%C3%A9tection%20et%20envoi%20d'alerte.png)

## Limites de cette version

Le code publié est une **version de démonstration issue du projet académique**, avec anonymisation de la configuration et retrait d'une ligne de console accidentellement présente dans `GenerateBaseline.ps1`. Il n'a pas été retesté dans cet environnement.

- Le moniteur compare les fichiers à une baseline fixe : sans mise à jour de cette baseline, il peut répéter la même alerte à chaque cycle.
- L'option 4 apparaît dans le menu `Admin.ps1`, mais elle n'est pas implémentée dans le script d'origine.
- La propriété `UseFileWatcher` figure dans la configuration, mais la version de `Monitor.ps1` publiée utilise la boucle périodique.
- `GenerateBaseline.ps1` traite les fichiers individuels ; la génération récursive d'une baseline pour des dossiers demanderait une amélioration.
- `Send-MailMessage` est une commande PowerShell historique, aujourd'hui déconseillée pour de nouvelles applications.

## Auteurs

Projet réalisé en équipe :
- Chaymaa TARGHI
- Yann TIO
- Sidi GANO

## Avertissement

Projet pédagogique de surveillance d'intégrité des fichiers. À adapter, tester et sécuriser avant toute utilisation hors laboratoire.
