# Security and privacy

*[Lire en français](security.fr.md)*

## What leaves your computer

Agenda contacts only the servers of the accounts you connect, and only to
read and write your events. There is no server of ours, no analytics, no
crash reporting and no update check: the plugin is updated by
`omarchy plugin update` like any other.

## Where things are kept

| What | Where | Protection |
|---|---|---|
| Passwords, app passwords, Google tokens, private calendar links | System keyring via `secret-tool`, attributes `service=dadoux01.agenda account=<id>` | Encrypted by the keyring |
| …when no keyring is available | `~/.local/state/dadoux01.agenda/secrets.json` | File mode 0600, directory 0700; the panel tells you when this happens |
| Accounts and calendars | `~/.config/dadoux01.agenda/accounts.json` | 0600; holds the marker `@keyring` instead of the password |
| Event cache | `~/.local/state/dadoux01.agenda/cache.json` | 0600 |

The helper writes files atomically. It refuses to read or write through a
symlink, or in a directory owned by another user.

## Google sign-in

- The plugin ships no Google client id or secret. Each user brings their own
  OAuth client ([google.md](google.md)), so no shared key can leak and no
  one but Google sits between you and your calendar.
- Sign-in follows the flow for installed apps (RFC 8252). A one-shot
  listener opens on `127.0.0.1` only, on a random port, and closes as soon
  as Google answers or after 5 minutes. It ignores any request without the
  random `state` value of this sign-in. The code is exchanged with **PKCE**
  (S256).
- Only two permissions are asked for: `calendar.events` and
  `calendar.calendarlist.readonly`. The refresh token, client id and client
  secret are stored together in the keyring. Access tokens stay in memory.
- Calendar links (`.ics`) can be secret addresses, so they go to the keyring
  too, never to `accounts.json`.

## How it talks to servers

- **https only**, TLS 1.2 or newer, with certificates checked against the
  system trust store.
- **Credentials stay in their domain.** Redirects are followed by hand. A
  password is attached only to the configured host and its own domain
  (`caldav.icloud.com` → `*.icloud.com`), never to a host a redirect points
  to elsewhere, and never over plain http.
- **Bounded:** every request has a timeout (12 s for reads, 15 s for writes,
  20 s for a calendar download) and responses over 10 MB are refused.
- **Safe writes:** a delete or change sends `If-Match` with the version you
  saw, so it never overwrites a change made elsewhere. A new event is
  created with `If-None-Match: *`, so it never replaces an existing one.

## Data from servers is treated as hostile

Event titles, places and notes can be written by anyone who invites you.

- **XML** with a `DOCTYPE` or an entity declaration is refused before it is
  parsed.
- **iCalendar** input is capped at 10 MB and 400,000 lines. Expanding a
  repeating event is capped at 500 occurrences per event and 100,000
  periods, so a crafted rule cannot freeze the shell.
- **Text in the UI** is always shown as plain text, so a title such as
  `<img src=…>` is displayed, never loaded. Calendar names passed to
  Omarchy's dropdowns have their markup characters replaced first.
- **Notifications:** the summary is plain text. In the body, the characters
  `<`, `>` and `&` are replaced with look-alikes, because Omarchy lets some
  tags, including links, through in notification bodies.
- **Video links** become a Join button only when they are `https://` on a
  known meeting host (Google Meet, Zoom, Teams, Webex, Jitsi, Whereby,
  Chime, FaceTime, GoTo). They open through `xdg-open` with the URL as a
  separate argument.

## Process isolation

- The network code and the secrets live in a separate Python process,
  started with `python3 -I -B`. Your environment, the current directory and
  user site-packages cannot inject code into it, and it writes no bytecode.
- It talks to the shell only through JSON lines on stdin and stdout.
  Passwords travel that way too, so they never appear in a command line
  (`ps`) or in a log.
- No shell command is ever built from data. Every subprocess (`secret-tool`,
  `notify-send`, `xdg-open`) gets an argument list.
- The helper depends only on the Python standard library.

## Reporting a vulnerability

Please open a private security advisory on the GitHub repository rather than
a public issue.
