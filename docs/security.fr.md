# Sécurité et confidentialité

*[Read in English](security.md)*

## Ce qui sort de ton ordinateur

Agenda contacte uniquement les serveurs des comptes que tu connectes, et
seulement pour lire et écrire tes événements. Il n'y a aucun serveur à nous,
aucune statistique, aucun rapport de plantage et aucune vérification de mise
à jour : le plugin se met à jour avec `omarchy plugin update`, comme les
autres.

## Où les données sont rangées

| Quoi | Où | Protection |
|---|---|---|
| Mots de passe et mots de passe d'app | Trousseau du système via `secret-tool`, attributs `service=dadoux01.agenda account=<id>` | Chiffré par le trousseau |
| …quand aucun trousseau n'est disponible | `~/.local/state/dadoux01.agenda/secrets.json` | Fichier en 0600, dossier en 0700 ; le panneau te prévient quand ça arrive |
| Comptes et calendriers | `~/.config/dadoux01.agenda/accounts.json` | 0600 ; contient le marqueur `@keyring` à la place du mot de passe |
| Cache des événements | `~/.local/state/dadoux01.agenda/cache.json` | 0600 |

Le service écrit les fichiers de façon atomique. Il refuse de lire ou
d'écrire à travers un lien symbolique, ou dans un dossier appartenant à un
autre utilisateur.

## Comment il parle aux serveurs

- **https uniquement**, en TLS 1.2 ou plus récent, avec vérification des
  certificats par le magasin de confiance du système.
- **Les identifiants restent dans leur domaine.** Les redirections sont
  suivies à la main. Un mot de passe n'est joint qu'à l'hôte configuré et à
  son propre domaine (`caldav.icloud.com` → `*.icloud.com`). Il n'est jamais
  envoyé à un hôte vers lequel une redirection pointe ailleurs, ni en http
  simple.
- **Limites :** chaque requête a un délai maximal (12 s en lecture, 15 s en
  écriture, 20 s pour télécharger un calendrier), et les réponses de plus de
  10 Mo sont refusées.
- **Écritures sûres :** une suppression ou une modification envoie
  `If-Match` avec la version que tu as vue, donc elle n'écrase jamais une
  modification faite ailleurs. Un nouvel événement est créé avec
  `If-None-Match: *`, donc il ne remplace jamais un événement existant.

## Les données des serveurs sont considérées comme hostiles

Les titres, lieux et notes d'événements peuvent être écrits par n'importe
qui t'envoyant une invitation.

- **XML :** une réponse contenant un `DOCTYPE` ou une déclaration d'entité
  est refusée avant d'être analysée.
- **iCalendar :** les données sont limitées à 10 Mo et 400 000 lignes. Le
  dépliage d'un événement récurrent est limité à 500 occurrences par
  événement et 100 000 périodes, pour qu'une règle piégée ne puisse pas
  geler le shell.
- **Texte dans l'interface :** il est toujours affiché en texte brut, donc un
  titre comme `<img src=…>` est affiché, jamais chargé. Les noms de
  calendriers passés aux menus déroulants d'Omarchy ont d'abord leurs
  caractères de balisage remplacés.
- **Notifications :** le titre est en texte brut. Dans le corps, les
  caractères `<`, `>` et `&` sont remplacés par des caractères ressemblants,
  car Omarchy laisse passer certaines balises, dont les liens, dans le corps
  des notifications.
- **Liens de visio :** ils ne deviennent un bouton Rejoindre que s'ils sont
  en `https://` sur un service de réunion connu (Google Meet, Zoom, Teams,
  Webex, Jitsi, Whereby, Chime, FaceTime, GoTo). Ils s'ouvrent avec
  `xdg-open`, l'URL étant passée comme argument séparé.

## Isolation du processus

- Le code réseau et les secrets vivent dans un processus Python séparé,
  lancé avec `python3 -I -B`. Ni ton environnement, ni le dossier courant, ni
  les site-packages utilisateur ne peuvent y injecter du code, et il n'écrit
  pas de bytecode.
- Il ne parle au shell que par des lignes JSON sur stdin et stdout. Les mots
  de passe passent aussi par là, donc ils n'apparaissent jamais dans une
  ligne de commande (`ps`) ni dans un journal.
- Aucune commande shell n'est construite à partir de données. Chaque
  sous-processus (`secret-tool`, `notify-send`, `xdg-open`) reçoit une liste
  d'arguments.
- Le service ne dépend que de la bibliothèque standard de Python.

## Signaler une vulnérabilité

Ouvre plutôt un avis de sécurité privé (security advisory) sur le dépôt
GitHub qu'un ticket public.
