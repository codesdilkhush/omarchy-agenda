"""When to notify. Pure functions, so they can be tested without a clock.

A reminder is identified by (event key, occurrence start, offset), so the
same reminder is never sent twice, across shell restarts and reboots, while
a moved event (new start) gets its reminders again.
"""

import datetime as dt

LATE_AFTER_MS = 2 * 60 * 1000
FIRED_KEEP_MS = 4 * 24 * 3600 * 1000


def reminder_offsets(event, settings):
    """Seconds-before-start values that apply to one event."""
    offsets = set()
    if settings.get("reminders", True):
        offsets.update(int(s) for s in event.get("alarms", []))
    extra = int(settings.get("extraReminderMinutes", 0) or 0)
    if extra > 0:
        offsets.add(extra * 60)
    if settings.get("notifyAtStart", True) and not event.get("allDay"):
        offsets.add(0)
    return sorted(offsets, reverse=True)


def fired_key(event, offset):
    return "%s|%d|%s" % (event["key"], int(event["start"]), offset)


def due(events, now_ms, fired, settings, snoozes=()):
    """Reminders to send now: a list of dicts {key, event, offset, late, kind}.

    A reminder is due once its time has come and for `lateGraceMinutes`
    after, which covers a machine that was asleep or off at the time.
    Older ones are dropped silently.
    """
    grace_ms = max(1, int(settings.get("lateGraceMinutes", 15))) * 60 * 1000
    out = []
    for ev in events:
        if ev.get("cancelled"):
            continue
        start = int(ev["start"])
        for offset in reminder_offsets(ev, settings):
            fire = start - offset * 1000
            key = fired_key(ev, offset)
            if key in fired:
                continue
            if fire <= now_ms <= fire + grace_ms:
                out.append({"key": key, "event": ev, "offset": offset,
                            "late": now_ms - fire > LATE_AFTER_MS,
                            "kind": "start" if offset == 0 else "before"})
        if settings.get("reminders", True):
            for at in ev.get("alarmsAt", []):
                key = "%s|%d|at%d" % (ev["key"], start, int(at))
                if key not in fired and at <= now_ms <= at + grace_ms:
                    out.append({"key": key, "event": ev, "offset": max(0, (start - at) // 1000),
                                "late": now_ms - at > LATE_AFTER_MS, "kind": "before"})
    by_key = {ev["key"]: ev for ev in events}
    for snooze in snoozes:
        if snooze["key"] in fired or snooze["at"] > now_ms:
            continue
        ev = by_key.get(snooze["eventKey"])
        if ev and now_ms <= int(ev["end"]) + grace_ms:
            out.append({"key": snooze["key"], "event": ev,
                        "offset": max(0, (int(ev["start"]) - now_ms) // 1000),
                        "late": False, "kind": "snooze"})
    out.sort(key=lambda r: (r["event"]["start"], -r["offset"]))
    return out


def prune_fired(fired, now_ms):
    return {k: v for k, v in fired.items() if now_ms - int(v) < FIRED_KEEP_MS}


def day_bounds(day, zone):
    start = dt.datetime(day.year, day.month, day.day, tzinfo=zone)
    end = start + dt.timedelta(days=1)
    # Rebuild from the wall date so a DST day is 23 or 25 hours long.
    nxt = (start + dt.timedelta(days=1, hours=12)).date()
    end = dt.datetime(nxt.year, nxt.month, nxt.day, tzinfo=zone)
    return int(start.timestamp() * 1000), int(end.timestamp() * 1000)


def events_on(events, day, zone):
    start, end = day_bounds(day, zone)
    out = [e for e in events if int(e["start"]) < end and max(int(e["end"]), int(e["start"]) + 1) > start]
    out.sort(key=lambda e: (not e.get("allDay"), int(e["start"]), e.get("title", "")))
    return out


def format_time(ms, zone, use24h=True):
    t = dt.datetime.fromtimestamp(ms / 1000, zone)
    if use24h:
        return t.strftime("%H:%M")
    hour = t.hour % 12 or 12
    return "%d:%02d %s" % (hour, t.minute, "AM" if t.hour < 12 else "PM")
