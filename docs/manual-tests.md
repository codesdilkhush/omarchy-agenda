# Manual tests before a release

*[Lire en français](manual-tests.fr.md)*

These are the checks the automated tests cannot do: clicking, receiving a
real notification, rebooting, signing in again. The whole list takes about
45 minutes. Tick the boxes as you go.

**Before you start**

- You need at least one Google account and one iCloud or CalDAV account.
- Use a test calendar, or events whose title starts with `TEST`, and delete
  them at the end.
- Keep the log open in a terminal:

  ```bash
  tail -f /run/user/$UID/quickshell/by-pid/$(pgrep -x quickshell | head -1)/log.log | grep -i agenda
  ```

  It should print nothing but `reloading` lines.

## 1. Bar

| ✓ | Action | Expected |
|---|---|---|
| ☐ | No event in the next 12 h | Only the 󰃭 icon shows. Hover: "N events today". |
| ☐ | Event starting in less than 1 h | "Title in N min", updated within 30 s. |
| ☐ | Event starting in less than 5 min | The label turns to the alert colour. |
| ☐ | Event in progress | "Title · N min left", or "until HH:MM" beyond 90 min. |
| ☐ | Very long title | The label stays within 24 characters, the time stays whole, and hovering shows the full text. |
| ☐ | Right-click the widget | The "New event" form opens. |
| ☐ | Middle-click | The sync icon spins in the popup and "Synced at" updates. |

## 2. Agenda and keyboard

| ✓ | Action | Expected |
|---|---|---|
| ☐ | Click the widget | Today comes first; today's past events are dimmed; empty days are hidden, except today. |
| ☐ | `↓` `↓` then `Enter` | The row is selected, then expands (notes, reminders, account). |
| ☐ | `j` on an event with a video link | The link opens in the browser and the popup closes. |
| ☐ | `s`, `a`, `,` then `Esc` | Sync; Accounts page; Settings page; back to the agenda. |
| ☐ | `Esc` on the agenda | The popup closes. |
| ☐ | Event from a read-only calendar (holidays) | No Delete button; `x` does nothing. |
| ☐ | Second monitor (if you have one): `omarchy-shell dadoux01.agenda toggle` | The popup opens only on the active monitor. |

## 3. Adding

Check every addition in the provider's app (web or phone).

| ✓ | Action | Expected |
|---|---|---|
| ☐ | Quick add `TEST dentist tomorrow 2pm-3pm` + Enter | "Event added" shows; the event is tomorrow 14:00–15:00 in the default calendar, and on the web. |
| ☐ | Quick add `TEST dentiste demain 14h-15h` | Same result. |
| ☐ | Quick add `TEST nothing to parse` | The form opens with that title. |
| ☐ | Form: all day, from 24/12 to 26/12 | One event over 3 days, not 2. |
| ☐ | Form: reminder "1 hour before" | The reminder shows on the event on the web **and** on the phone. |
| ☐ | Form with an invalid date (`31/02/2026`) | "Check the date" shows; nothing is created. |
| ☐ | Add on Google, then on iCloud | Both work, each in the right calendar. |

## 4. Deleting

In the web app, create a daily series `TEST series` of 5 days, **on Google
and on iCloud**, then sync (`s`).

| ✓ | Action | Expected |
|---|---|---|
| ☐ | Delete a single event | A 2-choice confirmation shows; the event disappears here and on the web. |
| ☐ | Google series: "This event only" on day 2 | Only day 2 disappears, here and on the web. |
| ☐ | Google series: "All events in the series" | The whole series disappears. |
| ☐ | Same on the iCloud series | Same result. |
| ☐ | Change an event on the web, then delete it here **without** syncing | "The event changed somewhere else" shows; nothing is overwritten. |
| ☐ | Cancel in the confirmation (button or `Esc`) | Nothing is deleted. |

## 5. Reminders and notifications

On the web, create an event `TEST reminder` starting **in 12 minutes**, with a
"10 minutes before" notification and a Google Meet link.

| ✓ | Action | Expected |
|---|---|---|
| ☐ | Wait about 2 min (sync + reminder) | A "TEST reminder" notification, "In 10 min · time", with the 󰃭 icon and the Join, Snooze 5 min and Open buttons. |
| ☐ | Click **Snooze 5 min** | The notification comes back 5 minutes later. |
| ☐ | Click **Open** | The popup opens on the active monitor. |
| ☐ | At the start time | A "Starting now" notification with Join. **Join** opens Meet. |
| ☐ | Restart the shell (`omarchy restart shell`) right after a reminder | The reminder is **not** sent again. |
| ☐ | Settings › Private notifications on, then repeat with another event | Title and place are hidden; no Join button. |
| ☐ | Settings › Calendar reminders off | No more reminders, only "Starting now" if that option is on. |
| ☐ | Settings › Extra reminder "2 minutes" | One more notification, 2 min before. |
| ☐ | Do Not Disturb on | No toast; the notifications land in history. |
| ☐ | Notification center | Agenda's notifications show the 󰃭 icon, not an "A". |

## 6. Daily recap

| ✓ | Action | Expected |
|---|---|---|
| ☐ | Reboot, or simulate with the commands below | A "Today" notification with today's events, at most 8 lines then "+N more". |
| ☐ | `omarchy restart shell` a second time | No second recap today. |
| ☐ | Suspend for more than 2 min, after simulating "yesterday" (commands below) | The recap arrives on wake-up. |
| ☐ | Empty day | "Nothing planned today". |
| ☐ | Settings › Daily recap off | No more recap. |

To make the plugin believe the last recap was yesterday:

```bash
python3 - <<'EOF'
import json, os, datetime
p = os.path.expanduser("~/.local/state/dadoux01.agenda/fired.json")
d = json.load(open(p))
d["lastRecapDay"] = (datetime.date.today() - datetime.timedelta(days=1)).isoformat()
json.dump(d, open(p, "w"))
EOF
omarchy restart shell        # recap at start-up
# or, to test waking up: run the script above again, then
systemctl suspend            # wait 2 min before waking the computer
```

## 7. Accounts

| ✓ | Action | Expected |
|---|---|---|
| ☐ | Accounts › hide a calendar | Its events leave the agenda and the bar, and no longer trigger reminders. |
| ☐ | Remove an account, then add it again | The account and its events disappear, then come back. Nothing is deleted on the server. |
| ☐ | Wrong iCloud password | "Wrong username or password… app-specific password". |
| ☐ | `.ics` link over `http://` | "Only https:// addresses are allowed". |
| ☐ | Valid `webcal://` link (holidays) | The calendar is added, read only. |
| ☐ | Google: revoke Agenda at myaccount.google.com/permissions, then `s` | The account shows "Google signed this account out" and a **Sign in again** button, which works. |
| ☐ | Google: close the popup while the browser is open | After signing in, the popup reopens by itself on the choice of calendars. |
| ☐ | Google: **Cancel** while waiting for the browser | Back to the client file choice, with no error message. |
| ☐ | `grep '"secret"' ~/.config/dadoux01.agenda/accounts.json` | Every account has `"secret": "@keyring"`, and no password shows. |

## 8. Robustness

| ✓ | Action | Expected |
|---|---|---|
| ☐ | Cut the network, then `s` | The agenda keeps its events; the status shows the sync error. |
| ☐ | Offline, at a reminder's time | The reminder still arrives. |
| ☐ | Restore the network | The error clears at the next sync. |
| ☐ | `pkill -f agenda_backend` | The service restarts by itself within 2 s; the agenda comes back. |
| ☐ | Setup › Language: switch to Français and back | The whole popup changes language without a restart. |
| ☐ | Change the Omarchy theme | The popup follows the theme's colours. |

## At the end

- Delete the `TEST` events and the test series.
- Reopen the popup: no error in the log.
- Write down what failed in the release's ticket, with the log line.
