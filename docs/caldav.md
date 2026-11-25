# Connect a CalDAV server

*[Lire en français](caldav.fr.md)*

CalDAV is the open standard most calendar services speak. Agenda reads and
writes events on any CalDAV server over **https**.

## Add the account

1. Calendar icon in the bar › **Connect a calendar** › **Other CalDAV server**.
2. **Username or e-mail**: usually your full e-mail address.
3. **Server address**: you can leave it empty for the providers in the
   table below. Agenda then finds the server from your e-mail address.
4. **Password or app password**: see the table. Most services want an app
   password rather than your main password.
5. **Connect**, pick the calendars, then **Save**.

## Providers

| Provider | Server address | Password |
|---|---|---|
| Fastmail | *(automatic)* `https://caldav.fastmail.com/` | App password: **Settings › Privacy & Security › Integrations › New app password**, access *Calendars (CalDAV)* |
| Nextcloud | `https://your.cloud/remote.php/dav` | App password: **Personal settings › Security › Devices & sessions › Create new app password** |
| Zoho | *(automatic)* `https://calendar.zoho.com/` (`.eu` for EU accounts) | App-specific password from **accounts.zoho.com › Security › App Passwords** |
| Yahoo | *(automatic)* `https://caldav.calendar.yahoo.com/` | App password: **Account security › Generate app password** |
| mailbox.org | *(automatic)* `https://dav.mailbox.org/` | Your password, or an app password if 2FA is on |
| GMX / WEB.DE | *(automatic)* | Your password (enable POP3/IMAP access first) |
| Posteo | *(automatic)* `https://posteo.de:8443/` | Your password |
| Radicale, Baïkal, SOGo, your own | the server's URL | Your password |

If your provider has no entry here, try your e-mail domain first. Agenda
then tries `https://<domain>/.well-known/caldav`. If that fails, ask your
provider for its "CalDAV URL".

## Notes

- **https only.** A plain `http://` server is refused, and so is a server
  whose certificate is not trusted by your system. For a self-hosted server
  with your own certificate authority, add the authority to the system trust
  store (`sudo trust anchor ca.pem`).
- Your password is sent only to the server you entered and to hosts in its
  domain (for example `p42-caldav.icloud.com` for `caldav.icloud.com`).
  It is never sent to a server a redirect points to elsewhere.
- Reminders (`VALARM`) on events are read and notified. Reminders you set in
  Agenda are written as `VALARM`, so other devices ring too.
- Repeating events are expanded on your computer. Daily, weekly, monthly and
  yearly rules are supported, including exceptions and moved occurrences.
