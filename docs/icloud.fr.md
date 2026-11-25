# Connecter Apple iCloud

*[Read in English](icloud.md)*

Les calendriers iCloud utilisent le standard CalDAV. Apple n'autorise pas
les apps tierces à se connecter avec le mot de passe de ton identifiant
Apple. Tu crées à la place un **mot de passe pour app** dédié à Agenda. Tu
peux le révoquer à tout moment sans toucher à ton vrai mot de passe.

## 1. Activer la double authentification

Les mots de passe pour app n'existent que pour les identifiants Apple avec
double authentification. Elle est déjà active sur presque tous les comptes.
Sinon, sur un iPhone : **Réglages › [ton nom] › Connexion et sécurité ›
Identification à deux facteurs**.

## 2. Créer le mot de passe pour app

1. Va sur <https://account.apple.com> et connecte-toi.
2. Ouvre **Connexion et sécurité › Mots de passe pour app**.
3. Clique sur **+** (ou **Générer un mot de passe pour app**).
4. Donne-lui un nom, par exemple `Omarchy Agenda`, et valide.
5. Apple affiche un mot de passe du type `abcd-efgh-ijkl-mnop`. Copie-le
   tout de suite : Apple ne le remontrera pas.

## 3. Ajouter le compte dans Agenda

1. Clique sur l'icône du calendrier dans la barre, puis sur **Connecter un
   calendrier** (ou **Comptes › +**).
2. Choisis **Apple iCloud**.
3. **E-mail de l'identifiant Apple** : l'adresse avec laquelle tu te
   connectes à iCloud.
4. **Mot de passe pour app** : colle le mot de passe, avec ou sans les
   tirets.
5. Clique sur **Connecter**, choisis les calendriers à afficher, puis
   **Enregistrer**.

Le mot de passe va dans le trousseau. Il n'est jamais écrit dans un fichier
de config, et il n'est envoyé qu'aux serveurs d'Apple (`*.icloud.com`).

## À savoir

- **Rappels** : les alertes réglées dans l'app Calendrier sur iPhone, iPad
  ou Mac arrivent avec chaque événement, et Agenda les notifie aussi ici.
  Un rappel réglé dans Agenda est enregistré sur l'événement, donc ton
  téléphone sonne aussi.
- **Les listes de l'app Rappels** (tâches) ne sont pas des calendriers
  d'événements, donc elles ne s'affichent pas.
- **Les calendriers partagés avec toi** que tu ne peux pas modifier sont
  marqués *Lecture seule*.
- **Révoquer l'accès** : supprime le mot de passe pour app sur
  account.apple.com, puis retire le compte dans **Comptes**.

## Problèmes

| Message | Solution |
|---|---|
| Identifiant ou mot de passe incorrect | Utilise le mot de passe pour app, pas celui de l'identifiant Apple. Vérifie l'adresse e-mail. |
| Impossible de joindre le serveur | Vérifie la connexion ; `caldav.icloud.com` doit être accessible. |
| Le mot de passe n'est plus dans le trousseau | Retire le compte puis rajoute-le. |
