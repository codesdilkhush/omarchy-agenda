# Connecter Google Agenda

*[Read in English](google.md)*

Agenda lit et écrit dans Google Agenda via l'API officielle de Google. Il
n'embarque **aucun identifiant Google** : tu crées ton propre client OAuth
dans ton propre projet Google Cloud. Ça prend environ 5 minutes, une seule
fois, et c'est gratuit. Ensuite, il n'y a que toi et Google : aucun serveur
intermédiaire, et aucun tiers qui pourrait perdre ou détourner une clé.

> Tu veux seulement *voir* un agenda Google, sans ajouter ni supprimer
> d'événements ? L'adresse secrète iCal est plus rapide à mettre en place :
> voir [ics.fr.md](ics.fr.md).

## 1. Créer un projet

1. Ouvre <https://console.cloud.google.com> et connecte-toi avec le compte
   Google dont tu veux l'agenda.
2. Clique sur le sélecteur de projet en haut, puis sur **Nouveau projet**.
3. Nomme-le `Omarchy Agenda` et clique sur **Créer**. Attends quelques
   secondes, puis vérifie que le nouveau projet est bien sélectionné.

## 2. Activer l'API Calendar

1. Menu ☰ › **API et services › Bibliothèque**.
2. Cherche **Google Calendar API**, ouvre-la et clique sur **Activer**.

## 3. Configurer l'écran de consentement

1. Menu ☰ › **Google Auth Platform** (aussi appelé **Écran de consentement
   OAuth**), puis **Commencer**.
2. **Nom de l'application** : `Omarchy Agenda`. **Adresse e-mail
   d'assistance** : ton adresse. Clique sur **Suivant**.
3. **Audience** : choisis **Externe**, puis **Suivant**.
4. **Coordonnées** : ton adresse. Clique sur **Suivant**, accepte le
   règlement, puis clique sur **Créer**.
5. Ouvre **Audience**. Tu as alors le choix :
   - **Publier l'application** (recommandé) : clique sur **Publier
     l'application**, puis **Confirmer**. Google te garde connecté jusqu'à
     ce que tu révoques l'accès. Pendant la connexion, Google affiche un
     avertissement *« Google n'a pas validé cette application »*, car l'app
     est la tienne et n'a jamais été soumise à Google. C'est normal.
   - **Rester en Test** : sous **Utilisateurs test**, clique sur **Add
     users** et ajoute ta propre adresse. Google déconnecte alors Agenda
     **tous les 7 jours**, et tu dois cliquer sur **Se reconnecter** dans
     **Comptes** à chaque fois.
6. Facultatif, mais ça rend l'écran de consentement plus clair : ouvre
   **Accès aux données › Ajouter ou supprimer des niveaux d'accès**, coche
   `.../auth/calendar.events` et `.../auth/calendar.calendarlist.readonly`,
   puis **Mettre à jour › Enregistrer**.

## 4. Créer le client OAuth

1. Ouvre **Clients › Créer un client**.
2. **Type d'application** : **Application de bureau**. Ce type précis est
   important : un client « Application Web » ne fonctionnera pas.
3. **Nom** : `Agenda`. Clique sur **Créer**.
4. Dans la fenêtre qui s'ouvre, clique sur **Télécharger le JSON**. Le
   fichier s'appelle `client_secret_…apps.googleusercontent.com.json`.
   Laisse-le dans **Téléchargements** : Agenda le cherche là.

## 5. Se connecter depuis Agenda

1. Icône du calendrier dans la barre › **Comptes › +** (ou **Connecter un
   calendrier**) › **Google**.
2. Agenda affiche les fichiers client trouvés dans Téléchargements. Clique
   sur le tien. Si le fichier est ailleurs, colle son chemin complet et
   clique sur **Se connecter avec Google**.
3. Ton navigateur s'ouvre sur la page de connexion de Google :
   - choisis le compte ;
   - si l'avertissement *« n'a pas validé cette application »* apparaît,
     clique sur **Paramètres avancés › Accéder à Omarchy Agenda (non
     sécurisé)**. C'est ta propre app ;
   - **laisse les deux cases de calendrier cochées**, puis clique sur
     **Continuer**.
4. L'onglet affiche *« Agenda est connecté »*. Reviens à la barre : le popup
   s'ouvre tout seul. Choisis les calendriers à afficher, puis
   **Enregistrer**.

Tu peux maintenant supprimer le fichier JSON téléchargé. Agenda garde l'ID
client, le secret client et le jeton de connexion dans le trousseau, jamais
dans un fichier de config.

## Ce qu'Agenda peut faire avec ton compte

| Autorisation | Pourquoi |
|---|---|
| `calendar.events` | lire, ajouter et supprimer des événements |
| `calendar.calendarlist.readonly` | lister tes agendas, leurs couleurs et leurs rappels par défaut |

Agenda ne peut lire ni tes mails, ni tes contacts, ni tes fichiers, et il ne
peut modifier ni les réglages ni le partage de tes agendas.

Pour révoquer l'accès à tout moment, va sur
<https://myaccount.google.com/permissions> › **Omarchy Agenda** ›
**Supprimer toutes les connexions**, puis retire le compte dans Agenda.

## Rappels

- Les notifications réglées sur chaque événement arrivent avec lui, y
  compris les **« notifications par défaut »** de chaque agenda (Google
  Agenda › Paramètres › ton agenda › Notifications d'événements). Elles
  deviennent des notifications sur le bureau.
- Les rappels par *e-mail* restent des e-mails. Seuls les rappels de type
  *notification* apparaissent sur le bureau.
- Un rappel choisi dans le formulaire d'Agenda est enregistré sur
  l'événement, donc ton téléphone sonne aussi.

## Problèmes

| Message | Solution |
|---|---|
| Ce n'est pas un fichier client OAuth Google | Télécharge le JSON d'un client **Application de bureau** (étape 4). |
| Ce client est de type « Application Web » | Crée un nouveau client de type **Application de bureau**. |
| Agenda a besoin des deux autorisations | Reconnecte-toi en laissant les deux cases cochées. |
| L'API Google Calendar n'est pas activée | Étape 2. Attends une minute après l'activation. |
| Google a déconnecté ce compte | **Comptes › Se reconnecter**. Si ça revient chaque semaine, publie l'app (étape 3.5). |
| `Erreur 403 : access_denied` dans le navigateur | L'app est en Test et ton adresse n'est pas utilisateur test (étape 3.5). |
| `Erreur 400 : redirect_uri_mismatch` | Le client n'est pas de type **Application de bureau**. |
| Google n'a pas accordé l'accès hors ligne | Révoque Agenda sur myaccount.google.com/permissions, puis reconnecte-toi. |
