# Connect Google Calendar

*[Lire en français](google.fr.md)*

Agenda reads and writes Google Calendar through Google's official API. It
ships **no Google credentials**: you create your own OAuth client in your
own Google Cloud project. That takes about 5 minutes, once, and costs
nothing. After that, nobody but you and Google is involved: no server in
the middle, and no third party that could lose or misuse a key.

> Just want to *see* a Google calendar, without adding or deleting events?
> The secret iCal address is faster to set up: see [ics.md](ics.md).

## 1. Create a project

1. Open <https://console.cloud.google.com> and sign in with the Google
   account whose calendar you want.
2. Click the project picker at the top, then **New project**.
3. Name it `Omarchy Agenda` and click **Create**. Wait a few seconds, then
   make sure the new project is selected in the picker.

## 2. Turn on the Calendar API

1. Menu ☰ › **APIs & Services › Library**.
2. Search for **Google Calendar API**, open it, and click **Enable**.

## 3. Set up the consent screen

1. Menu ☰ › the **›** arrow next to **APIs & Services** › **OAuth consent
   screen**. It leads to **Google Auth Platform**. (Or type
   `Google Auth Platform` in the search bar at the top.) Click **Get
   started**.
2. **App name**: `Omarchy Agenda`. **User support email**: your address.
   Click **Next**.
3. **Audience**: choose **External**, then **Next**.
4. **Contact information**: your address. Click **Next**, accept the policy,
   and click **Create**.
5. Open **Audience**. You now have a choice:
   - **Publish app** (recommended): click **Publish app**, then **Confirm**.
     Google keeps you signed in until you revoke access. During sign-in,
     Google shows a *"Google hasn't verified this app"* warning, because
     the app is yours and was never sent to Google for review. That is
     expected.
   - **Stay in Testing**: under **Test users**, click **Add users** and add
     your own address. Google then signs Agenda out **every 7 days**, and
     you click **Sign in again** under **Accounts** each time.
6. Optional, but it makes the consent screen clearer: open **Data Access ›
   Add or remove scopes**, tick `.../auth/calendar.events` and
   `.../auth/calendar.calendarlist.readonly`, then **Update › Save**.

## 4. Create the OAuth client

1. Open **Clients › Create client**.
2. **Application type**: **Desktop app**. This exact type matters: a "Web
   application" client will not work.
3. **Name**: `Agenda`. Click **Create**.
4. In the dialog that opens, click **Download JSON**. The file is named
   `client_secret_…apps.googleusercontent.com.json`. Leave it in
   **Downloads**: Agenda looks for it there.

## 5. Sign in from Agenda

1. Calendar icon in the bar › **Accounts › +** (or **Connect a calendar**)
   › **Google**.
2. Agenda lists the client files it found in Downloads. Click yours. If the
   file is somewhere else, paste its full path and click **Sign in with
   Google**.
3. Your browser opens on Google's sign-in page:
   - choose the account;
   - if the *"hasn't verified this app"* warning shows, click **Advanced ›
     Go to Omarchy Agenda (unsafe)**. It is your own app;
   - **leave both calendar boxes ticked**, then click **Continue**.
4. The browser tab says *"Agenda is connected"*. Go back to the bar: the
   popup opens on its own. Choose the calendars to show, then **Save**.

You can now delete the downloaded JSON file. Agenda keeps the client id, the
client secret and the sign-in token in your keyring, never in a config file.

## What Agenda can do with your account

| Permission | Why |
|---|---|
| `calendar.events` | read, add and delete events |
| `calendar.calendarlist.readonly` | list your calendars, their colours and default reminders |

It cannot read your mail, contacts or files, and it cannot change calendar
settings or sharing.

To revoke access at any time, go to <https://myaccount.google.com/permissions>
› **Omarchy Agenda** › **Delete all connections**, then remove the account
in Agenda.

## Reminders

- The notifications set on each event come with it, including **"default
  notifications"** of each calendar (Google Calendar › Settings › your
  calendar › Event notifications). They are sent as desktop notifications.
- *Email* reminders stay emails. Only *notification* reminders show up on
  the desktop.
- A reminder chosen in Agenda's form is saved on the event, so your phone
  rings too.

## Problems

| Message | Fix |
|---|---|
| That is not a Google OAuth client file | Download the JSON of a **Desktop app** client (step 4). |
| This client is of type "Web application" | Create a new client of type **Desktop app**. |
| Agenda needs both calendar permissions | Sign in again and leave both boxes ticked. |
| The Google Calendar API is not enabled | Step 2. Wait a minute after enabling it. |
| Google signed this account out | **Accounts › Sign in again**. If it happens every week, publish the app (step 3.5). |
| `Error 403: access_denied` in the browser | The app is in Testing and your address is not a test user (step 3.5). |
| `Error 400: redirect_uri_mismatch` | The client is not of type **Desktop app**. |
| Google did not grant offline access | Revoke Agenda at myaccount.google.com/permissions, then sign in again. |
