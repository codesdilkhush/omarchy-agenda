# Connect Apple iCloud

*[Lire en français](icloud.fr.md)*

iCloud calendars use the CalDAV standard. Apple does not let third-party apps
sign in with your Apple ID password. You create an **app-specific
password** for Agenda instead. You can revoke it at any time without
touching your real password.

## 1. Turn on two-factor authentication

App-specific passwords exist only for Apple IDs with two-factor
authentication. Almost every Apple ID has it already. If yours does not:
on an iPhone, go to **Settings › [your name] › Sign-In & Security ›
Two-Factor Authentication**.

## 2. Create the app-specific password

1. Go to <https://account.apple.com> and sign in.
2. Open **Sign-In and Security › App-Specific Passwords**.
3. Click **+** (or **Generate an app-specific password**).
4. Name it, for example `Omarchy Agenda`, and confirm.
5. Apple shows a password like `abcd-efgh-ijkl-mnop`. Copy it now: Apple
   will not show it again.

## 3. Add the account in Agenda

1. Click the calendar icon in the bar, then **Connect a calendar** (or
   **Accounts › +**).
2. Choose **Apple iCloud**.
3. **Apple ID e-mail**: the address you sign in to iCloud with.
4. **App-specific password**: paste the password, with or without the dashes.
5. Click **Connect**, pick the calendars to show, then **Save**.

The password goes to your keyring. It is never written in a config file and
never sent anywhere but Apple's servers (`*.icloud.com`).

## Notes

- **Reminders**: the alerts you set in the Calendar app on iPhone, iPad or
  Mac come along with each event, and Agenda notifies them here too.
  Reminders set in Agenda are saved on the event, so your phone rings as
  well.
- **Apple Reminders lists** (to-dos) are not calendars of events, so they
  are not shown.
- **Calendars shared with you** that you cannot edit show *Read only*.
- **Revoke access**: delete the app-specific password on account.apple.com,
  then remove the account under **Accounts**.

## Problems

| Message | Fix |
|---|---|
| Wrong username or password | Use the app-specific password, not your Apple ID password. Check the e-mail address. |
| Can't reach the server | Check your connection; `caldav.icloud.com` must be reachable. |
| The password is no longer in the keyring | Remove the account and add it again. |
