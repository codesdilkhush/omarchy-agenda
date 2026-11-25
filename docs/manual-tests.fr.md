# Tests manuels avant une version

*[Read in English](manual-tests.md)*

Ce sont les vérifications que les tests automatiques ne peuvent pas faire :
cliquer, recevoir une vraie notification, redémarrer, se reconnecter. Il faut
compter environ 45 minutes pour toute la liste. Coche au fur et à mesure.

**Avant de commencer**

- Il faut au moins un compte Google et un compte iCloud ou CalDAV.
- Utilise un calendrier de test, ou des événements dont le titre commence par
  `TEST`, et supprime-les à la fin.
- Garde le journal ouvert dans un terminal :

  ```bash
  tail -f /run/user/$UID/quickshell/by-pid/$(pgrep -x quickshell | head -1)/log.log | grep -i agenda
  ```

  Il ne doit rien afficher d'autre que des lignes `reloading`.

## 1. Barre

| ✓ | Action | Résultat attendu |
|---|---|---|
| ☐ | Sans événement dans les 12 h | Seule l'icône 󰃭 s'affiche. Au survol : « N événements aujourd'hui ». |
| ☐ | Événement qui commence dans moins d'1 h | « Titre dans N min », mis à jour en moins de 30 s. |
| ☐ | Événement qui commence dans moins de 5 min | Le libellé passe en couleur d'alerte. |
| ☐ | Événement en cours | « Titre · encore N min », ou « jusqu'à HH:MM » au-delà de 90 min. |
| ☐ | Titre très long | Le libellé ne dépasse pas 24 caractères, l'heure reste entière, le survol montre le texte complet. |
| ☐ | Clic droit sur le widget | Le formulaire « Nouvel événement » s'ouvre. |
| ☐ | Clic du milieu | L'icône de synchro tourne dans le popup, l'heure « Synchronisé à » se met à jour. |

## 2. Agenda et clavier

| ✓ | Action | Résultat attendu |
|---|---|---|
| ☐ | Clic sur le widget | Aujourd'hui en premier ; les événements passés d'aujourd'hui sont estompés ; les jours vides sont masqués, sauf aujourd'hui. |
| ☐ | `↓` `↓` puis `Entrée` | La ligne est sélectionnée, puis se déplie (notes, rappels, compte). |
| ☐ | `j` sur un événement avec visio | Le lien s'ouvre dans le navigateur et le popup se ferme. |
| ☐ | `s`, `a`, `,` puis `Échap` | Synchro ; page Comptes ; page Réglages ; retour à l'agenda. |
| ☐ | `Échap` sur l'agenda | Le popup se ferme. |
| ☐ | Événement d'un calendrier en lecture seule (jours fériés) | Pas de bouton Supprimer ; `x` ne fait rien. |
| ☐ | Écran secondaire (si tu en as un) : `omarchy-shell dadoux01.agenda toggle` | Le popup s'ouvre uniquement sur l'écran actif. |

## 3. Ajout

Vérifie chaque ajout dans l'app du fournisseur (web ou téléphone).

| ✓ | Action | Résultat attendu |
|---|---|---|
| ☐ | Ajout rapide `TEST dentiste demain 14h-15h` + Entrée | Le message « Événement ajouté » s'affiche ; l'événement est demain 14:00–15:00 dans le calendrier par défaut et sur le web. |
| ☐ | Ajout rapide `TEST lunch friday 1pm` | Vendredi, 13:00–14:00. |
| ☐ | Ajout rapide `TEST rien à analyser` | Le formulaire s'ouvre avec ce titre. |
| ☐ | Formulaire : toute la journée, du 24/12 au 26/12 | Un événement sur 3 jours, et non 2. |
| ☐ | Formulaire : rappel « 1 heure avant » | Le rappel apparaît sur l'événement côté web **et** sur le téléphone. |
| ☐ | Formulaire avec une date invalide (`31/02/2026`) | Le message « Vérifie la date » s'affiche ; rien n'est créé. |
| ☐ | Ajout sur Google, puis sur iCloud | Les deux fonctionnent, chacun dans le bon calendrier. |

## 4. Suppression

Prépare dans l'app web une série quotidienne `TEST série` de 5 jours,
**sur Google et sur iCloud**, puis lance une synchro (`s`).

| ✓ | Action | Résultat attendu |
|---|---|---|
| ☐ | Supprimer un événement simple | Une confirmation à 2 choix s'affiche ; l'événement disparaît ici et sur le web. |
| ☐ | Série Google : « Cet événement seulement » sur le 2e jour | Seul le 2e jour disparaît, ici et sur le web. |
| ☐ | Série Google : « Toute la série » | Toute la série disparaît. |
| ☐ | Même chose sur la série iCloud | Même résultat. |
| ☐ | Modifier un événement sur le web, puis le supprimer ici **sans** synchroniser | Le message « L'événement a changé ailleurs » s'affiche ; rien n'est écrasé. |
| ☐ | Annuler dans la confirmation (bouton ou `Échap`) | Rien n'est supprimé. |

## 5. Rappels et notifications

Crée sur le web un événement `TEST rappel` qui commence **dans 12 minutes**,
avec une notification « 10 minutes avant » et un lien Google Meet.

| ✓ | Action | Résultat attendu |
|---|---|---|
| ☐ | Attendre environ 2 min (synchro + rappel) | Une notification « TEST rappel », « Dans 10 min · heure », avec l'icône 󰃭 et les boutons Rejoindre, Rappeler dans 5 min, Ouvrir. |
| ☐ | Cliquer sur **Rappeler dans 5 min** | La notification revient 5 minutes plus tard. |
| ☐ | Cliquer sur **Ouvrir** | Le popup s'ouvre sur l'écran actif. |
| ☐ | À l'heure de début | Une notification « Commence maintenant » avec Rejoindre. **Rejoindre** ouvre Meet. |
| ☐ | Redémarrer le shell (`omarchy restart shell`) juste après un rappel | Le rappel n'est **pas** renvoyé. |
| ☐ | Réglages › Notifications discrètes, puis répéter avec un autre événement | Le titre et le lieu sont masqués ; pas de bouton Rejoindre. |
| ☐ | Réglages › Rappels du calendrier désactivés | Plus de rappel, seulement « Commence maintenant » si cette option est active. |
| ☐ | Réglages › Rappel en plus « 2 minutes » | Une notification de plus, 2 min avant. |
| ☐ | Ne pas déranger activé | Aucun toast ; les notifications arrivent dans l'historique. |
| ☐ | Centre de notifications | Les notifications d'Agenda ont l'icône 󰃭, pas un « A ». |

## 6. Récap du jour

| ✓ | Action | Résultat attendu |
|---|---|---|
| ☐ | Redémarrer l'ordinateur, ou simuler avec les commandes ci-dessous | Une notification « Aujourd'hui » avec les événements du jour, au plus 8 lignes puis « +N autres ». |
| ☐ | `omarchy restart shell` une deuxième fois | Pas de deuxième récap aujourd'hui. |
| ☐ | Veille pendant plus de 2 min, après avoir simulé « hier » (commandes ci-dessous) | Le récap arrive au réveil. |
| ☐ | Journée vide | « Rien de prévu aujourd'hui ». |
| ☐ | Réglages › Récap du jour désactivé | Plus de récap. |

Pour faire croire au plugin que le dernier récap date d'hier :

```bash
python3 - <<'EOF'
import json, os, datetime
p = os.path.expanduser("~/.local/state/dadoux01.agenda/fired.json")
d = json.load(open(p))
d["lastRecapDay"] = (datetime.date.today() - datetime.timedelta(days=1)).isoformat()
json.dump(d, open(p, "w"))
EOF
omarchy restart shell        # récap au démarrage
# ou, pour tester la sortie de veille : relance le script ci-dessus, puis
systemctl suspend            # attends 2 min avant de réveiller
```

## 7. Comptes

| ✓ | Action | Résultat attendu |
|---|---|---|
| ☐ | Comptes › masquer un calendrier | Ses événements disparaissent de l'agenda et de la barre, et ne déclenchent plus de rappel. |
| ☐ | Retirer un compte puis le rajouter | Le compte et ses événements disparaissent, puis reviennent. Rien n'est supprimé sur le serveur. |
| ☐ | Mauvais mot de passe iCloud | « Identifiant ou mot de passe incorrect… mot de passe pour app ». |
| ☐ | Lien `.ics` en `http://` | « Seules les adresses https:// sont acceptées ». |
| ☐ | Lien `webcal://` valide (jours fériés) | Le calendrier est ajouté en lecture seule. |
| ☐ | Google : révoquer Agenda sur myaccount.google.com/permissions, puis `s` | Le compte affiche « Google a déconnecté ce compte » et un bouton **Se reconnecter**, qui fonctionne. |
| ☐ | Google : fermer le popup pendant que le navigateur est ouvert | Après la connexion, le popup se rouvre de lui-même sur le choix des calendriers. |
| ☐ | Google : **Annuler** pendant l'attente du navigateur | Retour au choix du fichier client, sans message d'erreur. |
| ☐ | `grep '"secret"' ~/.config/dadoux01.agenda/accounts.json` | Chaque compte a `"secret": "@keyring"`, et aucun mot de passe n'apparaît. |

## 8. Robustesse

| ✓ | Action | Résultat attendu |
|---|---|---|
| ☐ | Couper le réseau, puis `s` | L'agenda garde ses événements ; le statut indique l'erreur de synchro. |
| ☐ | Hors ligne, à l'heure d'un rappel | Le rappel arrive quand même. |
| ☐ | Rétablir le réseau | L'erreur disparaît à la synchro suivante. |
| ☐ | `pkill -f agenda_backend` | Le service redémarre seul en moins de 2 s ; l'agenda revient. |
| ☐ | Setup › Language : passer en English puis revenir | Tout le popup change de langue sans redémarrage. |
| ☐ | Changer de thème Omarchy | Le popup suit les couleurs du thème. |

## À la fin

- Supprime les événements `TEST` et la série de test.
- Rouvre le popup : aucune erreur dans le journal.
- Note dans le ticket de la version ce qui a échoué, avec la ligne du journal.
