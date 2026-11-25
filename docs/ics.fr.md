# Ajouter un lien de calendrier (.ics)

*[Read in English](ics.md)*

Beaucoup de services publient un calendrier sous forme d'un seul fichier
`.ics` à une adresse fixe. Agenda peut l'afficher en **lecture seule** : tu
vois les événements et tu reçois leurs rappels, mais tu ne peux pas y
ajouter ni y supprimer d'événement.

1. Icône du calendrier dans la barre › **Comptes › +** › **Lien de
   calendrier (.ics)**.
2. Colle le lien. Il commence par `https://` ou `webcal://`.
3. **Connecter**, puis **Enregistrer**.

## Où trouver le lien

| Service | Où |
|---|---|
| **Google Agenda** | calendar.google.com › ⚙ Paramètres › ton agenda › **Intégrer l'agenda › Adresse secrète au format iCal** |
| **Proton Calendar** | Paramètres › Calendriers › ton calendrier › **Partager › Partager avec n'importe qui** › vue complète › copier le lien |
| **Outlook.com / Microsoft 365** | Paramètres › Calendrier › Calendriers partagés › **Publier un calendrier** › choisir le calendrier et *Peut afficher tous les détails* › lien **ICS** |
| **iCloud** (calendrier public) | app Calendrier › calendrier › Partager › **Calendrier public** › copier le lien `webcal://` |
| **Jours fériés, sport, vacances scolaires** | le lien « s'abonner » ou « iCal » sur la page de l'éditeur |

## À savoir

- **Un lien privé vaut un mot de passe.** Quiconque possède une adresse
  « secrète » ou « privée » peut lire le calendrier. Agenda range le lien
  dans le trousseau, pas dans un fichier de config. Pour couper l'accès,
  réinitialise l'adresse secrète chez le service.
- **Délai** : c'est le service qui fabrique le fichier, pas Agenda. Google,
  par exemple, peut mettre plusieurs heures à mettre à jour son adresse
  secrète iCal. Pour voir les changements tout de suite, connecte plutôt le
  compte lui-même : [google.fr.md](google.fr.md) ou [caldav.fr.md](caldav.fr.md).
- Agenda demande au serveur si le fichier a changé (`ETag`,
  `If-Modified-Since`) et ne le retélécharge que si c'est le cas.
- **https uniquement.** Les liens `webcal://` sont récupérés en https ; les
  liens en `http://` simple sont refusés.
