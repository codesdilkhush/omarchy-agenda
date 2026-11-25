# Connecter un serveur CalDAV

*[Read in English](caldav.md)*

CalDAV est le standard ouvert que parlent la plupart des services de
calendrier. Agenda lit et écrit les événements sur n'importe quel serveur
CalDAV en **https**.

## Ajouter le compte

1. Icône du calendrier dans la barre › **Connecter un calendrier** ›
   **Autre serveur CalDAV**.
2. **Identifiant ou e-mail** : en général ton adresse e-mail complète.
3. **Adresse du serveur** : tu peux la laisser vide pour les fournisseurs du
   tableau ci-dessous. Agenda trouve alors le serveur à partir de ton
   adresse e-mail.
4. **Mot de passe ou mot de passe d'app** : voir le tableau. La plupart des
   services demandent un mot de passe d'application plutôt que le principal.
5. **Connecter**, choisis les calendriers, puis **Enregistrer**.

## Fournisseurs

| Fournisseur | Adresse du serveur | Mot de passe |
|---|---|---|
| Fastmail | *(automatique)* `https://caldav.fastmail.com/` | Mot de passe d'app : **Settings › Privacy & Security › Integrations › New app password**, accès *Calendars (CalDAV)* |
| Nextcloud | `https://ton.cloud/remote.php/dav` | Mot de passe d'app : **Paramètres personnels › Sécurité › Appareils et sessions › Créer un mot de passe d'application** |
| Zoho | *(automatique)* `https://calendar.zoho.com/` (`.eu` pour les comptes européens) | Mot de passe d'app sur **accounts.zoho.com › Sécurité › Mots de passe d'application** |
| Yahoo | *(automatique)* `https://caldav.calendar.yahoo.com/` | Mot de passe d'app : **Sécurité du compte › Générer un mot de passe d'application** |
| mailbox.org | *(automatique)* `https://dav.mailbox.org/` | Ton mot de passe, ou un mot de passe d'app si la 2FA est active |
| GMX / WEB.DE | *(automatique)* | Ton mot de passe (active d'abord l'accès POP3/IMAP) |
| Posteo | *(automatique)* `https://posteo.de:8443/` | Ton mot de passe |
| Radicale, Baïkal, SOGo, ton serveur | l'URL du serveur | Ton mot de passe |

Si ton fournisseur n'apparaît pas ici, essaie d'abord ton domaine e-mail.
Agenda tente alors `https://<domaine>/.well-known/caldav`. Si ça échoue,
demande à ton fournisseur son « URL CalDAV ».

## À savoir

- **https uniquement.** Un serveur en `http://` simple est refusé, tout
  comme un serveur dont le certificat n'est pas reconnu par le système. Pour
  un serveur auto-hébergé avec ta propre autorité de certification, ajoute
  celle-ci au magasin de confiance du système (`sudo trust anchor ca.pem`).
- Ton mot de passe n'est envoyé qu'au serveur indiqué et aux hôtes de son
  domaine (par exemple `p42-caldav.icloud.com` pour `caldav.icloud.com`). Il
  n'est jamais envoyé à un serveur vers lequel une redirection pointe
  ailleurs.
- Les rappels (`VALARM`) des événements sont lus et notifiés. Les rappels
  réglés dans Agenda sont écrits en `VALARM`, donc tes autres appareils
  sonnent aussi.
- Les événements récurrents sont dépliés sur ton ordinateur. Les règles
  quotidiennes, hebdomadaires, mensuelles et annuelles sont gérées, avec les
  exceptions et les occurrences déplacées.
