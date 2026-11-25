# Add a calendar link (.ics)

*[Lire en français](ics.fr.md)*

Many services publish a calendar as a single `.ics` file at a fixed address.
Agenda can show it **read only**: you see the events and get their
reminders, but you cannot add or delete events in it.

1. Calendar icon in the bar › **Accounts › +** › **Calendar link (.ics)**.
2. Paste the link. It starts with `https://` or `webcal://`.
3. **Connect**, then **Save**.

## Where to find the link

| Service | Where |
|---|---|
| **Google Calendar** | calendar.google.com › ⚙ Settings › your calendar › **Integrate calendar › Secret address in iCal format** |
| **Proton Calendar** | Settings › Calendars › your calendar › **Share › Share with anyone** › full view › copy the link |
| **Outlook.com / Microsoft 365** | Settings › Calendar › Shared calendars › **Publish a calendar** › choose the calendar and *Can view all details* › **ICS** link |
| **iCloud** (a public calendar) | Calendar app › calendar › Share › **Public Calendar** › copy the `webcal://` link |
| **Public holidays, sports, school terms** | the "subscribe" or "iCal" link on the publisher's page |

## Good to know

- **Private links are passwords.** Anyone who has a "secret" or "private"
  address can read the calendar. Agenda keeps the link in your keyring, not
  in a config file. To cut access, reset the secret address at the service.
- **Delay**: the service builds the file, not Agenda. Google, for instance,
  can take several hours to update its secret iCal address. For changes to
  show at once, connect the account itself: [google.md](google.md) or
  [caldav.md](caldav.md).
- Agenda asks the server whether the file changed (`ETag`,
  `If-Modified-Since`) and downloads it again only when it did.
- **https only.** `webcal://` links are fetched over https; plain `http://`
  links are refused.
