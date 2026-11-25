"""Accounts, sync, and writes, independent of how requests arrive.

Providers sit behind one small interface (discover / list / create / delete)
so adding Google or Microsoft later is one module, not a rewrite.
"""

import datetime as dt
import hashlib
import secrets as _random
import threading
import time
import urllib.parse

from . import caldav, ics, net, secrets, storage

ACCOUNTS_FILE = "accounts.json"
SETTINGS_FILE = "settings.json"
CACHE_FILE = "cache.json"

WINDOW_PAST_DAYS = 1
WINDOW_FUTURE_DAYS = 62
PENDING_TTL = 600

PALETTE = ["#7aa2f7", "#9ece6a", "#e0af68", "#f7768e", "#bb9af7", "#7dcfff",
           "#ff9e64", "#73daca", "#c0caf5", "#db4b4b"]

DEFAULT_SETTINGS = {
    "syncMinutes": 10,
    "reminders": True,
    "extraReminderMinutes": 0,
    "notifyAtStart": True,
    "privateNotifications": False,
    "dailyRecap": True,
    "lateGraceMinutes": 15,
    "defaultReminderMinutes": 10,
    "defaultCalendar": "",
    "agendaDays": 7,
}

SETTING_LIMITS = {
    "syncMinutes": (2, 120),
    "extraReminderMinutes": (0, 1440),
    "lateGraceMinutes": (1, 120),
    "defaultReminderMinutes": (-1, 10080),
    "agendaDays": (1, 31),
}

PROVIDERS = ("caldav",)
KINDS = ("icloud", "caldav")


class EngineError(Exception):
    def __init__(self, code, detail=""):
        super().__init__(code)
        self.code = code
        self.detail = detail


def _clean(value, limit):
    value = "".join(c for c in str(value or "") if c == "\n" or ord(c) >= 32)
    return value.strip()[:limit]


def event_key(account_id, calendar_id, uid, rid):
    raw = "\x1f".join([account_id, calendar_id, uid, rid or ""])
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:20]


class Engine:
    def __init__(self):
        self.lock = threading.RLock()
        self.zone = ics.local_zone()
        self.accounts = self._load_accounts()
        self.settings = self._load_settings()
        self.cache = storage.read_json(storage.state_path(CACHE_FILE), {})
        if not isinstance(self.cache, dict) or self.cache.get("version") != 1:
            self.cache = {"version": 1, "calendars": {}, "syncedAt": 0, "errors": {}}
        self.pending = {}
        self.syncing = False

    # ------------------------------------------------------------ files

    def _load_accounts(self):
        data = storage.read_json(storage.config_path(ACCOUNTS_FILE), {})
        accounts = data.get("accounts", []) if isinstance(data, dict) else []
        out = []
        for acc in accounts:
            if not isinstance(acc, dict) or acc.get("provider") not in PROVIDERS:
                continue
            if not isinstance(acc.get("id"), str) or not isinstance(acc.get("calendars"), list):
                continue
            out.append(acc)
        return out

    def _save_accounts(self):
        storage.write_json(storage.config_path(ACCOUNTS_FILE),
                           {"version": 1, "accounts": self.accounts})

    def _load_settings(self):
        data = storage.read_json(storage.config_path(SETTINGS_FILE), {})
        merged = dict(DEFAULT_SETTINGS)
        if isinstance(data, dict):
            merged.update(self._validate_settings(data))
        return merged

    def _validate_settings(self, values):
        out = {}
        for key, default in DEFAULT_SETTINGS.items():
            if key not in values:
                continue
            v = values[key]
            if isinstance(default, bool):
                if isinstance(v, bool):
                    out[key] = v
            elif isinstance(default, int):
                if isinstance(v, (int, float)) and not isinstance(v, bool):
                    lo, hi = SETTING_LIMITS.get(key, (0, 10 ** 6))
                    out[key] = int(min(hi, max(lo, v)))
            elif isinstance(default, str):
                if isinstance(v, str) and len(v) <= 2000:
                    out[key] = v
        return out

    def set_settings(self, values):
        with self.lock:
            self.settings.update(self._validate_settings(values or {}))
            storage.write_json(storage.config_path(SETTINGS_FILE), self.settings)
            return dict(self.settings)

    def _save_cache(self):
        storage.write_json(storage.state_path(CACHE_FILE), self.cache)

    # ------------------------------------------------------------ accounts

    def public_accounts(self):
        errors = self.cache.get("errors", {})
        out = []
        for acc in self.accounts:
            out.append({
                "id": acc["id"],
                "provider": acc["provider"],
                "kind": acc.get("kind", acc["provider"]),
                "label": acc.get("label", ""),
                "username": acc.get("username", ""),
                "server": acc.get("server", ""),
                "error": errors.get(acc["id"], ""),
                "calendars": [{
                    "id": c["id"], "name": c.get("name", ""), "color": c.get("color", ""),
                    "enabled": bool(c.get("enabled", True)), "readOnly": bool(c.get("readOnly")),
                } for c in acc["calendars"]],
            })
        return out

    def _account(self, account_id):
        for acc in self.accounts:
            if acc["id"] == account_id:
                return acc
        raise EngineError("unknown_account")

    def _password(self, acc):
        secret = secrets.load(acc["id"], acc.get("secret", ""))
        if not secret:
            raise EngineError("missing_secret")
        return secret

    def discover(self, kind, server, username, password, label=""):
        if kind not in KINDS:
            raise EngineError("unknown_provider")
        username = _clean(username, 320)
        password = str(password or "")
        if not username or not password or len(password) > 1024:
            raise EngineError("missing_credentials")
        if kind == "icloud":
            server = "https://caldav.icloud.com/"
        try:
            base, cals = caldav.discover(server, username, password)
        except net.NetError as exc:
            # iCloud answers 403, not 401, to an Apple ID / app password it
            # does not accept, so the user gets the message that helps.
            code = "auth_failed" if exc.code == "forbidden" and kind == "icloud" else exc.code
            raise EngineError(code, exc.detail)
        for i, cal in enumerate(cals):
            if not cal.get("color"):
                cal["color"] = PALETTE[i % len(PALETTE)]
        token = _random.token_hex(16)
        now = time.time()
        with self.lock:
            self.pending = {k: v for k, v in self.pending.items() if now - v["at"] < PENDING_TTL}
            self.pending[token] = {
                "at": now, "kind": kind, "server": base, "username": username,
                "password": password, "calendars": cals,
                "label": _clean(label, 80) or ("iCloud" if kind == "icloud"
                                               else urllib.parse.urlsplit(base).hostname or "CalDAV"),
            }
        return {"token": token, "label": self.pending[token]["label"],
                "calendars": [{k: c[k] for k in ("id", "name", "color", "readOnly")} for c in cals]}

    def save_account(self, token, label, selection):
        with self.lock:
            pending = self.pending.pop(token, None)
        if not pending or time.time() - pending["at"] > PENDING_TTL:
            raise EngineError("pending_expired")
        chosen = {s.get("id"): s for s in (selection or []) if isinstance(s, dict)}
        account_id = _random.token_hex(6)
        cals = []
        for cal in pending["calendars"]:
            sel = chosen.get(cal["id"], {})
            color = caldav.normalize_color(str(sel.get("color", ""))) or cal["color"]
            cals.append({"id": cal["id"], "name": cal["name"], "color": color,
                         "enabled": bool(sel.get("enabled", True)), "readOnly": cal["readOnly"]})
        marker = secrets.store(account_id, pending["password"])
        account = {
            "id": account_id, "provider": "caldav", "kind": pending["kind"],
            "label": _clean(label, 80) or pending["label"], "server": pending["server"],
            "username": pending["username"], "secret": marker, "calendars": cals,
        }
        with self.lock:
            self.accounts.append(account)
            self._save_accounts()
        return {"id": account_id, "secretStore": marker}

    def update_account(self, account_id, label=None, calendars=None):
        with self.lock:
            acc = self._account(account_id)
            if label is not None:
                acc["label"] = _clean(label, 80) or acc.get("label", "")
            if isinstance(calendars, list):
                by_id = {c.get("id"): c for c in calendars if isinstance(c, dict)}
                for cal in acc["calendars"]:
                    upd = by_id.get(cal["id"])
                    if not upd:
                        continue
                    if "enabled" in upd:
                        cal["enabled"] = bool(upd["enabled"])
                    if "color" in upd:
                        cal["color"] = caldav.normalize_color(str(upd["color"])) or cal["color"]
            self._save_accounts()

    def remove_account(self, account_id):
        with self.lock:
            acc = self._account(account_id)
            self.accounts = [a for a in self.accounts if a["id"] != account_id]
            self._save_accounts()
            cals = self.cache.get("calendars", {})
            for key in [k for k in cals if k.startswith(account_id + "|")]:
                del cals[key]
            self.cache.get("errors", {}).pop(account_id, None)
            self._save_cache()
        secrets.delete(acc["id"])

    # ------------------------------------------------------------ sync

    def window(self, now=None):
        today = (now or dt.datetime.now(self.zone)).astimezone(self.zone).date()
        start_day = today - dt.timedelta(days=WINDOW_PAST_DAYS)
        end_day = today + dt.timedelta(days=WINDOW_FUTURE_DAYS)
        start = dt.datetime(start_day.year, start_day.month, start_day.day, tzinfo=self.zone)
        end = dt.datetime(end_day.year, end_day.month, end_day.day, tzinfo=self.zone)
        return start, end

    def sync(self, force=False, only=None):
        """Refresh every enabled calendar. `only` = set of cache keys to
        refetch regardless of their ctag."""
        with self.lock:
            accounts = [dict(a, calendars=[dict(c) for c in a["calendars"]]) for a in self.accounts]
            self.syncing = True
        start, end = self.window()
        window_ms = int(start.timestamp() * 1000)
        errors = {}
        fresh = {}
        try:
            for acc in accounts:
                try:
                    password = self._password(acc)
                except EngineError as exc:
                    errors[acc["id"]] = exc.code
                    continue
                client = caldav.Client(acc["server"], acc["username"], password)
                for cal in acc["calendars"]:
                    if not cal.get("enabled", True):
                        continue
                    ckey = acc["id"] + "|" + cal["id"]
                    cached = self.cache.get("calendars", {}).get(ckey)
                    try:
                        ctag = ""
                        try:
                            ctag = client.ctag(cal["id"])
                        except net.NetError as exc:
                            if exc.code in ("auth_failed", "forbidden", "not_found"):
                                raise
                        if (not force and cached and ctag and cached.get("ctag") == ctag
                                and cached.get("windowStart") == window_ms
                                and not (only and ckey in only)):
                            fresh[ckey] = cached
                            continue
                        items = client.fetch_range(cal["id"], start.astimezone(ics.UTC),
                                                   end.astimezone(ics.UTC))
                        fresh[ckey] = {"ctag": ctag, "windowStart": window_ms,
                                       "events": self._events_for(acc, cal, items, start, end)}
                    except (net.NetError, ics.IcsError) as exc:
                        errors[acc["id"]] = getattr(exc, "code", None) or str(exc)
                        if cached:
                            fresh[ckey] = cached
        finally:
            with self.lock:
                self.syncing = False
        with self.lock:
            self.cache["calendars"] = fresh
            self.cache["errors"] = errors
            self.cache["syncedAt"] = int(time.time() * 1000)
            self._save_cache()
        return errors

    def _events_for(self, acc, cal, items, start, end):
        out = []
        for item in items:
            try:
                occs = ics.events_from_calendar(item["data"], start, end, self.zone)
            except ics.IcsError:
                continue
            for o in occs:
                out.append({
                    "key": event_key(acc["id"], cal["id"], o["uid"], o["recurrence_id"]),
                    "accountId": acc["id"],
                    "calendarId": cal["id"],
                    "uid": o["uid"][:500],
                    "href": item["href"],
                    "etag": item["etag"],
                    "title": o["title"],
                    "location": o["location"],
                    "description": o["description"],
                    "start": o["start_ms"],
                    "end": o["end_ms"],
                    "allDay": o["all_day"],
                    "recurring": o["recurring"],
                    "recurrenceId": o["recurrence_id"],
                    "meetingUrl": o["meeting_url"],
                    "alarms": o["alarms_before"],
                    "alarmsAt": o["alarms_at"],
                })
                if len(out) >= 20000:
                    return out
        return out

    def events(self):
        """Every cached occurrence, decorated with its calendar's look."""
        with self.lock:
            cal_info = {}
            for acc in self.accounts:
                for cal in acc["calendars"]:
                    cal_info[acc["id"] + "|" + cal["id"]] = (acc, cal)
            out = []
            for ckey, entry in self.cache.get("calendars", {}).items():
                info = cal_info.get(ckey)
                if not info or not info[1].get("enabled", True):
                    continue
                acc, cal = info
                for ev in entry.get("events", []):
                    e = dict(ev)
                    e["calendarName"] = cal.get("name", "")
                    e["accountLabel"] = acc.get("label", "")
                    e["color"] = cal.get("color", "")
                    e["readOnly"] = bool(cal.get("readOnly"))
                    out.append(e)
        out.sort(key=lambda e: (e["start"], e["title"]))
        return out

    def find_event(self, key):
        for ev in self.events():
            if ev["key"] == key:
                return ev
        raise EngineError("unknown_event")

    # ------------------------------------------------------------ writes

    def _writable(self, account_id, calendar_id):
        acc = self._account(account_id)
        for cal in acc["calendars"]:
            if cal["id"] == calendar_id:
                if cal.get("readOnly"):
                    raise EngineError("read_only")
                return acc, cal
        raise EngineError("unknown_calendar")

    def create_event(self, p):
        acc, cal = self._writable(str(p.get("accountId", "")), str(p.get("calendarId", "")))
        title = _clean(p.get("title"), 300)
        if not title:
            raise EngineError("missing_title")
        try:
            start_ms, end_ms = int(p["start"]), int(p["end"])
        except (KeyError, TypeError, ValueError):
            raise EngineError("bad_time")
        if end_ms <= start_ms or end_ms - start_ms > 366 * 86400 * 1000:
            raise EngineError("bad_time")
        all_day = bool(p.get("allDay"))
        reminders = []
        for m in p.get("reminders", []) or []:
            if isinstance(m, (int, float)) and not isinstance(m, bool) and 0 <= m <= 40320:
                reminders.append(int(m))
        if all_day:
            start = dt.datetime.fromtimestamp(start_ms / 1000, self.zone).date()
            end = dt.datetime.fromtimestamp(end_ms / 1000, self.zone).date()
            if end <= start:
                end = start + dt.timedelta(days=1)
        else:
            start = dt.datetime.fromtimestamp(start_ms / 1000, ics.UTC)
            end = dt.datetime.fromtimestamp(end_ms / 1000, ics.UTC)
        uid, text = ics.build_event(title, start, end, all_day,
                                    _clean(p.get("location"), 300),
                                    _clean(p.get("description"), 2000), reminders)
        client = caldav.Client(acc["server"], acc["username"], self._password(acc))
        try:
            client.put_new(cal["id"], uid, text)
        except net.NetError as exc:
            raise EngineError(exc.code, exc.detail)
        return {"calendarKey": acc["id"] + "|" + cal["id"]}

    def delete_event(self, key, scope):
        ev = self.find_event(key)
        acc, cal = self._writable(ev["accountId"], ev["calendarId"])
        client = caldav.Client(acc["server"], acc["username"], self._password(acc))
        try:
            if scope == "occurrence" and ev.get("recurring") and ev.get("recurrenceId"):
                for _ in range(2):
                    etag, text = client.get(ev["href"])
                    try:
                        updated = ics.add_exdate(text, ev["uid"], ev["recurrenceId"])
                    except ics.IcsError as exc:
                        raise EngineError("bad_event", str(exc))
                    try:
                        client.put_existing(ev["href"], updated, etag)
                        break
                    except net.NetError as exc:
                        if exc.code != "conflict":
                            raise
                else:
                    raise EngineError("conflict")
            else:
                client.delete(ev["href"], ev.get("etag", ""))
        except net.NetError as exc:
            raise EngineError(exc.code, exc.detail)
        return {"calendarKey": acc["id"] + "|" + cal["id"]}
